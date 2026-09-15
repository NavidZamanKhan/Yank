String timeAgo(DateTime time) {
  final elapsed = DateTime.now().difference(time);
  if (elapsed.inMinutes < 1) {
    return 'Just now';
  }
  if (elapsed.inHours < 1) {
    return '${elapsed.inMinutes} min ago';
  }
  if (elapsed.inDays < 1) {
    return '${elapsed.inHours} hr ago';
  }
  if (elapsed.inDays == 1) {
    return 'Yesterday';
  }
  return '${elapsed.inDays} days ago';
}

String dayLabel(DateTime time) {
  final now = DateTime.now();
  final date = DateTime(time.year, time.month, time.day);
  final days = DateTime(now.year, now.month, now.day).difference(date).inDays;
  if (days <= 0) {
    return 'Today';
  }
  if (days == 1) {
    return 'Yesterday';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[time.month - 1]} ${time.day}';
}

String fileSize(int bytes) => bytes >= 1000000
    ? '${(bytes / 1000000).toStringAsFixed(1)} MB'
    : '${(bytes / 1000).round()} KB';
String audioTime(Duration duration) =>
    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
