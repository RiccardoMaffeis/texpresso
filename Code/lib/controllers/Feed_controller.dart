import '../models/Feed_model.dart';

class FeedController {
  // In a real app this would fetch from a repository or API
  void follow(Feed activity) {
    // qui la logica per seguire l’utente,
    // per esempio invii una request o aggiorni lo stato
    print('Segui ${activity.username}');
  }

  Future<List<Feed>> fetchActivities() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Feed(
        username: 'starryskies23',
        avatarUrl: 'https://img.freepik.com/vettori-premium/immagine-di-profilo-dell-avatar-dell-uomo-isolata-sullo-sfondo-immagina-di-profilo-avatar-per-l-uomo_1293239-4841.jpg?semt=ais_hybrid&w=740',
        timeAgo: '1d',
        actionText: 'Started following you',
        showFollowButton: true,
      ),
      Feed(
        username: 'starryskies23',
        avatarUrl: 'https://img.freepik.com/vettori-premium/immagine-di-profilo-dell-avatar-dell-uomo-isolata-sullo-sfondo-immagina-di-profilo-avatar-per-l-uomo_1293239-4841.jpg?semt=ais_hybrid&w=740',
        timeAgo: '1d',
        actionText: 'Ti ha taggato, controlla!',
        thumbnailUrl: 'https://m.media-amazon.com/images/I/91N1lG+LBIS._AC_UF1000,1000_QL80_DpWeblab_.jpg',
      ),
      // ... altri item
    ];
  }
}
