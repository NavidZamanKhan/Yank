import UIKit
import MobileCoreServices
import Photos
import UniformTypeIdentifiers

private let kUserDefaultsKey = "ShareKey"
private let kUserDefaultsMessageKey = "ShareMessageKey"
private let kAppGroupIdKey = "AppGroupId"

enum SharedMediaType: String, Codable, CaseIterable {
    case image
    case video
    case text
    case file
    case url

    var utTypeIdentifier: String {
        if #available(iOS 14.0, *) {
            switch self {
            case .image:
                return UTType.image.identifier
            case .video:
                return UTType.movie.identifier
            case .text:
                return UTType.text.identifier
            case .file:
                return UTType.fileURL.identifier
            case .url:
                return UTType.url.identifier
            }
        }
        switch self {
        case .image:
            return "public.image"
        case .video:
            return "public.movie"
        case .text:
            return "public.text"
        case .file:
            return "public.file-url"
        case .url:
            return "public.url"
        }
    }
}

class SharedMediaFile: Codable {
    var path: String
    var mimeType: String?
    var thumbnail: String?
    var duration: Double?
    var message: String?
    var type: SharedMediaType

    init(
        path: String,
        mimeType: String? = nil,
        thumbnail: String? = nil,
        duration: Double? = nil,
        message: String? = nil,
        type: SharedMediaType
    ) {
        self.path = path
        self.mimeType = mimeType
        self.thumbnail = thumbnail
        self.duration = duration
        self.message = message
        self.type = type
    }
}

class ShareViewController: UIViewController {
    private var hostAppBundleIdentifier = ""
    private var appGroupId = ""
    private var sharedMedia: [SharedMediaFile] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        loadIds()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .clear
        var ancestor = view.superview
        while let current = ancestor {
            current.backgroundColor = .clear
            current.isOpaque = false
            ancestor = current.superview
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        processSharedContent()
    }

    private func loadIds() {
        let shareBundleId = Bundle.main.bundleIdentifier ?? ""
        if let lastIndex = shareBundleId.lastIndex(of: ".") {
            hostAppBundleIdentifier = String(shareBundleId[..<lastIndex])
        } else {
            hostAppBundleIdentifier = "com.example.yank"
        }

        let customGroupId = Bundle.main.object(forInfoDictionaryKey: kAppGroupIdKey) as? String
        appGroupId = customGroupId ?? "group.\(hostAppBundleIdentifier)"
    }

    private func processSharedContent() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem], !items.isEmpty else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        let dispatchGroup = DispatchGroup()

        for item in items {
            guard let attachments = item.attachments else { continue }
            for attachment in attachments {
                for mediaType in SharedMediaType.allCases {
                    let identifier = mediaType.utTypeIdentifier
                    if attachment.hasItemConformingToTypeIdentifier(identifier) {
                        dispatchGroup.enter()
                        attachment.loadItem(forTypeIdentifier: identifier, options: nil) { [weak self] (data, error) in
                            defer { dispatchGroup.leave() }
                            guard let self = self, error == nil else { return }
                            self.handleItem(data: data, type: mediaType)
                        }
                        break
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.saveAndComplete()
        }
    }

    private func handleItem(data: NSSecureCoding?, type: SharedMediaType) {
        switch type {
        case .text:
            if let text = data as? String {
                sharedMedia.append(SharedMediaFile(path: text, type: .text))
            }
        case .url:
            if let url = data as? URL {
                sharedMedia.append(SharedMediaFile(path: url.absoluteString, type: .url))
            }
        case .image:
            if let url = data as? URL {
                if let savedPath = copyToSharedContainer(url: url) {
                    sharedMedia.append(SharedMediaFile(path: savedPath, mimeType: url.mimeType(), type: .image))
                }
            } else if let image = data as? UIImage {
                if let savedPath = saveImageToSharedContainer(image: image) {
                    sharedMedia.append(SharedMediaFile(path: savedPath, mimeType: "image/png", type: .image))
                }
            }
        case .video:
            if let url = data as? URL {
                if let savedPath = copyToSharedContainer(url: url) {
                    let videoInfo = getVideoInfo(url: url)
                    sharedMedia.append(
                        SharedMediaFile(
                            path: savedPath,
                            mimeType: url.mimeType(),
                            thumbnail: videoInfo?.thumbnail,
                            duration: videoInfo?.duration,
                            type: .video
                        )
                    )
                }
            }
        case .file:
            if let url = data as? URL {
                if let savedPath = copyToSharedContainer(url: url) {
                    sharedMedia.append(SharedMediaFile(path: savedPath, mimeType: url.mimeType(), type: .file))
                }
            }
        }
    }

    private func sharedContainerURL() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    private func copyToSharedContainer(url: URL) -> String? {
        guard let container = sharedContainerURL() else { return nil }
        let baseName = url.lastPathComponent.isEmpty ? "file" : url.lastPathComponent
        let uniqueName = "\(UUID().uuidString.prefix(8))_\(baseName)"
        let destination = container.appendingPathComponent(uniqueName)

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: url, to: destination)
            return destination.path
        } catch {
            return nil
        }
    }

    private func saveImageToSharedContainer(image: UIImage) -> String? {
        guard let container = sharedContainerURL() else { return nil }
        let fileName = "\(UUID().uuidString).png"
        let destination = container.appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            if let data = image.pngData() {
                try data.write(to: destination)
                return destination.path
            }
        } catch {
            return nil
        }
        return nil
    }

    private func getVideoInfo(url: URL) -> (thumbnail: String?, duration: Double)? {
        let asset = AVAsset(url: url)
        let duration = (CMTimeGetSeconds(asset.duration) * 1000).rounded()

        guard let container = sharedContainerURL() else {
            return (nil, duration)
        }

        let thumbName = "\(UUID().uuidString)_thumb.jpg"
        let thumbURL = container.appendingPathComponent(thumbName)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 360, height: 360)

        do {
            let cgImage = try generator.copyCGImage(at: CMTimeMakeWithSeconds(1, preferredTimescale: 600), actualTime: nil)
            if let data = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8) {
                try data.write(to: thumbURL)
                return (thumbURL.path, duration)
            }
        } catch {
            // thumbnail generation fallback
        }

        return (nil, duration)
    }

    private func saveAndComplete() {
        guard !sharedMedia.isEmpty else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        let userDefaults = UserDefaults(suiteName: appGroupId)
        var cumulativeMedia = [SharedMediaFile]()

        // Accumulate unread shares if user shared multiple items before opening Yank
        if let existingData = userDefaults?.data(forKey: kUserDefaultsKey),
           let existingMedia = try? JSONDecoder().decode([SharedMediaFile].self, from: existingData) {
            cumulativeMedia.append(contentsOf: existingMedia)
        }

        cumulativeMedia.append(contentsOf: sharedMedia)

        if let encoded = try? JSONEncoder().encode(cumulativeMedia) {
            userDefaults?.set(encoded, forKey: kUserDefaultsKey)
            userDefaults?.synchronize()
        }

        // Complete the extension silently without launching or foregrounding the host app
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

extension URL {
    func mimeType() -> String {
        if #available(iOS 14.0, *) {
            if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
                return mimeType
            }
        } else {
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self.pathExtension as NSString, nil)?.takeRetainedValue() {
                if let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                    return mimeType as String
                }
            }
        }
        return "application/octet-stream"
    }
}
