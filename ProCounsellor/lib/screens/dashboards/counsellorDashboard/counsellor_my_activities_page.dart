import 'package:flutter/material.dart';
import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/followers_page.dart';
import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/subscribers_page.dart';
import 'counsellor_chat_page.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/call_history_page.dart';

class CounsellorMyActivitiesPage extends StatefulWidget {
  final String username;
  final Future<void> Function() onSignOut;

  CounsellorMyActivitiesPage({required this.username, required this.onSignOut});

  @override
  _CounsellorMyActivitiesPageState createState() =>
      _CounsellorMyActivitiesPageState();
}

class _CounsellorMyActivitiesPageState
    extends State<CounsellorMyActivitiesPage> {
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    try {
      await Future.wait([
        precacheImage(
            AssetImage("images/my_activity_subscribers.jpg"), context),
        precacheImage(AssetImage("images/followers.jpg"), context),
        precacheImage(AssetImage("images/chat.png"), context),
        precacheImage(AssetImage("images/calls.jpg"), context),
        precacheImage(AssetImage("images/play.png"), context),
        precacheImage(AssetImage("images/bookmarking.png"), context),
        precacheImage(AssetImage("images/article.png"), context),
        precacheImage(AssetImage("images/community.png"), context),
      ]);
    } catch (e) {
      print("Error during image preloading: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.orangeAccent,
                size: 50,
              ),
            )
          : Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: ListView(
                children: [
                  buildActivityRow(
                    context,
                    "images/my_activity_counsellor_subs1.jpg",
                    "My Subscribers",
                    SubscribersPage(
                        counsellorId: widget.username,
                        onSignOut: widget.onSignOut),
                    isReversed: false,
                  ),
                  buildDivider(),
                  buildActivityRow(
                    context,
                    "images/follow.jpg",
                    "My Followers",
                    FollowersPage(
                      counsellorId: widget.username,
                      onSignOut: widget.onSignOut,
                    ),
                    isReversed: true,
                  ),
                  buildDivider(),
                  buildActivityRow(
                    context,
                    "images/chat.png",
                    "Chats",
                    ChatPage(
                      counsellorId: widget.username,
                      onSignOut: widget.onSignOut,
                    ),
                    isReversed: false,
                  ),
                  buildDivider(),
                  buildActivityRow(
                    context,
                    "images/calls.jpg",
                    "Calls (Video/Audio)",
                    CallHistoryPage(
                        counsellorId: widget.username,
                        onSignOut: widget.onSignOut), // ✅ Update Here
                    isReversed: true,
                  ),
                  buildDivider(),
                  buildActivityRow(
                    context,
                    "images/play.png",
                    "Liked Videos",
                    null,
                    isReversed: false,
                    routeName: '/liked_videos',
                  ),
                  buildDivider(),
                  buildActivityRow(
                    context,
                    "images/bookmarking.png",
                    "Liked Articles",
                    null,
                    isReversed: true,
                    routeName: '/liked_articles',
                  ),
                  buildDivider(),
                  buildActivityRow(
                    context,
                    "images/article.png",
                    "Saved Articles",
                    null,
                    isReversed: false,
                    routeName: '/saved_articles',
                  ),
                  buildDivider(),
                  buildActivityRow(
                    context,
                    "images/community.png",
                    "My Community",
                    null,
                    isReversed: true,
                    routeName: '/my_communities',
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildActivityRow(
    BuildContext context,
    String imageAsset,
    String title,
    Widget? nextPage, {
    required bool isReversed,
    String? routeName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isReversed ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isReversed)
            buildImageCard(imageAsset, context, nextPage, routeName),
          SizedBox(width: 16),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: isReversed ? TextAlign.end : TextAlign.start,
            ),
          ),
          if (isReversed) SizedBox(width: 16),
          if (isReversed)
            buildImageCard(imageAsset, context, nextPage, routeName),
        ],
      ),
    );
  }

  Widget buildImageCard(String imageAsset, BuildContext context,
      Widget? nextPage, String? routeName) {
    return GestureDetector(
      onTap: () {
        if (nextPage != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => nextPage));
        } else if (routeName != null) {
          Navigator.pushNamed(context, routeName);
        }
      },
      child: Container(
        height: 120,
        width: MediaQuery.of(context).size.width * 0.6,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imageAsset),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDivider() {
    return Divider(
      color: Colors.grey[300],
      thickness: 1,
      height: 16,
    );
  }
}
