String formatElapsed(int mins) {
    if (mins < 60) return '$mins minutes ago';
    final h = mins ~/ 60;
    if (h < 24) return '$h hours ago';
    final d = h ~/ 24;
    if (d < 7) return '$d days ago';
    final w = d ~/ 7;
    if (w < 4) return '$w weeks ago';
    final m = d ~/ 30;
    if (m < 12) return '$m months ago';
    return '${d ~/ 365} years ago';
  }