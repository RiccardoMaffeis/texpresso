import 'package:flutter/material.dart';
import '../controllers/Feed_controller.dart';
import '../controllers/BottomNavBarController.dart';
import '../models/Feed_model.dart';
import 'BottomNavBar.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final FeedController _activityController = FeedController();
  final BottomNavBarController _navController = BottomNavBarController(
    initialIndex: 2,
  );
  late Future<List<Feed>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = _activityController.fetchActivities();
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 249, 221, 168),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Activity', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Feed>>(
          future: _activitiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
           if (snapshot.hasError) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Si è verificato un errore durante il caricamento.\n'
        'Controlla la connessione e riprova più tardi.',
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
            final activities = snapshot.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: activities.length,
              itemBuilder: (context, idx) {
                final act = activities[idx];
                return FeedItemView(
                  activity: act,
                  onFollow: () => _activityController.follow(act),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _navController.selectedIndex,
        onTap: (idx) => _navController.changeTab(idx, context),
      ),
    );
  }
}

// Componente per singolo elemento Feed
class FeedItemView extends StatelessWidget {
  final Feed activity;
  final VoidCallback? onFollow;

  const FeedItemView({Key? key, required this.activity, this.onFollow})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00796B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(activity.avatarUrl),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      activity.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activity.timeAgo,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity.actionText,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          if (activity.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                activity.thumbnailUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          if (activity.showFollowButton)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ElevatedButton(
                onPressed: onFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // <— qui
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Segui'), // correggi anche “Tex” → “Text”
              ),
            ),
        ],
      ),
    );
  }
}
