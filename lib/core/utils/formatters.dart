/// Formatting helpers. Byte counts and timestamps are machine values, so they
/// are computed once here rather than scattered across screens.
library;

class Fmt {
  const Fmt._();

  static const _units = ['B', 'KB', 'MB', 'GB', 'TB'];

  /// Human byte count. Uses 1024 steps and caps at two decimals so a column of
  /// sizes stays visually even.
  static String bytes(num value) {
    if (value <= 0) return '0 B';
    var n = value.toDouble();
    var i = 0;
    while (n >= 1024 && i < _units.length - 1) {
      n /= 1024;
      i++;
    }
    final text = i == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(1);
    return '$text ${_units[i]}';
  }

  /// Exact byte count, grouped — used where precision matters (receipts).
  static String bytesExact(num value) {
    final digits = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return '${buf.toString()} bytes';
  }

  /// Transfer speed, bytes per second.
  static String speed(num bytesPerSecond) {
    if (bytesPerSecond <= 0) return '—';
    return '${bytes(bytesPerSecond)}/s';
  }

  /// "3 seconds left" / "2 minutes left". `null` when the moment has passed.
  static String? remaining(DateTime expiresAt, DateTime now) {
    final d = expiresAt.difference(now);
    if (d.isNegative || d.inSeconds <= 0) return null;
    if (d.inSeconds < 60) return '${d.inSeconds}s left';
    if (d.inMinutes < 60) {
      final m = d.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} left';
    }
    if (d.inHours < 24) {
      final h = d.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} left';
    }
    final days = d.inDays;
    return '$days ${days == 1 ? 'day' : 'days'} left';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String date(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]} · $h:$m';
  }

  static String dayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  /// Relative time for transfer history: "just now", "4m ago", "3d ago".
  static String ago(DateTime then, DateTime now) {
    final d = now.difference(then);
    if (d.inSeconds < 45) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return dayMonth(then);
  }

  /// Truncates a filename in the middle so the extension always survives —
  /// extensions carry the file's identity and shouldn't be the part that gets
  /// chopped off.
  static String ellipsizeMiddle(String value, int max) {
    if (value.length <= max) return value;
    final dot = value.lastIndexOf('.');
    final ext = (dot > 0 && value.length - dot <= 6) ? value.substring(dot) : '';
    final stem = ext.isEmpty ? value : value.substring(0, dot);
    final keep = max - ext.length;
    final head = (keep / 2).ceil();
    final tail = keep - head;
    if (tail < 1) return '${value.substring(0, max)}…';
    return '${stem.substring(0, head)}…${stem.substring(stem.length - tail)}$ext';
  }

  /// Pluralise without a second pass at the call site.
  static String plural(int n, String one, [String? many]) =>
      n == 1 ? '$n $one' : '$n ${many ?? '${one}s'}';
}