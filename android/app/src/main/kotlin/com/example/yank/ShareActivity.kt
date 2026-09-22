package com.example.yank

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class ShareActivity : Activity() {
    private val tag = "ShareActivity"
    private val prefsName = "com.example.yank.share_prefs"
    private val shareKey = "ShareKey"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        overridePendingTransition(0, 0)

        try {
            handleIntent(intent)
        } catch (e: Exception) {
            Log.e(tag, "Failed to handle share intent", e)
        } finally {
            Toast.makeText(applicationContext, "Yanked", Toast.LENGTH_SHORT).show()
            finish()
            overridePendingTransition(0, 0)
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        val action = intent.action
        val items = mutableListOf<JSONObject>()

        if (Intent.ACTION_SEND == action) {
            handleSend(intent, items)
        } else if (Intent.ACTION_SEND_MULTIPLE == action) {
            handleSendMultiple(intent, items)
        }

        if (items.isNotEmpty()) {
            savePendingShares(items)
        }
    }

    private fun handleSend(intent: Intent, items: MutableList<JSONObject>) {
        val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

        if (uri != null) {
            processStreamUri(uri, intent.type, items)
            return
        }

        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            ?: intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()

        if (!text.isNullOrBlank()) {
            val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
            val trimmed = text.trim()
            val isUrl = trimmed.startsWith("http://", ignoreCase = true) ||
                    trimmed.startsWith("https://", ignoreCase = true)

            val item = JSONObject().apply {
                put("path", trimmed)
                put("mimeType", "text/plain")
                put("thumbnail", JSONObject.NULL)
                put("duration", JSONObject.NULL)
                put("message", if (!subject.isNullOrBlank()) subject else JSONObject.NULL)
                put("type", if (isUrl) "url" else "text")
            }
            items.add(item)
        }
    }

    private fun handleSendMultiple(intent: Intent, items: MutableList<JSONObject>) {
        val uris: ArrayList<Uri>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
        }

        uris?.forEach { uri ->
            processStreamUri(uri, intent.type, items)
        }
    }

    private fun processStreamUri(uri: Uri, intentType: String?, items: MutableList<JSONObject>) {
        val mimeType = contentResolver.getType(uri) ?: intentType ?: "application/octet-stream"
        val originalName = getDisplayName(uri)

        val sharesDir = File(cacheDir, "shares").apply { mkdirs() }
        val safeName = originalName.replace(Regex("[^a-zA-Z0-9._-]"), "_")
        val destFile = File(sharesDir, "${UUID.randomUUID()}_$safeName")

        try {
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(destFile).use { output ->
                    val buffer = ByteArray(8192)
                    var bytesRead: Int
                    while (input.read(buffer).also { bytesRead = it } != -1) {
                        output.write(buffer, 0, bytesRead)
                    }
                }
            }

            val typeString = when {
                mimeType.startsWith("image/") -> "image"
                mimeType.startsWith("video/") -> "video"
                mimeType.startsWith("audio/") -> "file"
                else -> "file"
            }

            val item = JSONObject().apply {
                put("path", destFile.absolutePath)
                put("mimeType", mimeType)
                put("thumbnail", JSONObject.NULL)
                put("duration", JSONObject.NULL)
                put("message", originalName)
                put("type", typeString)
            }
            items.add(item)
        } catch (e: Exception) {
            Log.e(tag, "Failed to copy stream from uri: $uri", e)
            if (destFile.exists()) {
                destFile.delete()
            }
        }
    }

    private fun getDisplayName(uri: Uri): String {
        var name = "shared_file"
        if (ContentResolver.SCHEME_CONTENT == uri.scheme) {
            try {
                contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (index != -1) {
                            val displayName = cursor.getString(index)
                            if (!displayName.isNullOrBlank()) {
                                name = displayName
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                Log.w(tag, "Failed to query display name for $uri", e)
            }
        } else if (ContentResolver.SCHEME_FILE == uri.scheme) {
            uri.lastPathSegment?.let { name = it }
        }
        return name
    }

    private fun savePendingShares(newItems: List<JSONObject>) {
        val prefs = getSharedPreferences(prefsName, Context.MODE_PRIVATE)
        val existingJson = prefs.getString(shareKey, null)
        val combinedArray = JSONArray()

        if (!existingJson.isNullOrBlank()) {
            try {
                val existingArray = JSONArray(existingJson)
                for (i in 0 until existingArray.length()) {
                    combinedArray.put(existingArray.getJSONObject(i))
                }
            } catch (e: Exception) {
                Log.e(tag, "Failed to parse existing pending shares JSON", e)
            }
        }

        for (item in newItems) {
            combinedArray.put(item)
        }

        prefs.edit().putString(shareKey, combinedArray.toString()).apply()
    }
}
