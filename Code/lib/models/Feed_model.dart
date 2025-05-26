class Feed {
  final String username;
  final String avatarUrl;
  final String timeAgo;
  final String actionText;
  final String? thumbnailUrl;
  final bool showFollowButton;

  Feed({
    required this.username,
    required this.avatarUrl,
    required this.timeAgo,
    required this.actionText,
    this.thumbnailUrl,
    this.showFollowButton = false,
  });
}

