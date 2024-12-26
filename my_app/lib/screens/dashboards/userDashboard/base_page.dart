import 'package:flutter/material.dart';
import 'user_dashboard.dart';
import 'my_activities_page.dart';
import 'learn_with_us_page.dart';
import 'community_page.dart';
import 'profile_page.dart';
import 'user_state_notifier.dart'; // Import UserStateNotifier

class BasePage extends StatefulWidget {
  final VoidCallback onSignOut;
  final String username;

  BasePage({required this.onSignOut, required this.username});

  @override
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late UserStateNotifier _userStateNotifier;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    // Add WidgetsBindingObserver to listen for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Initialize UserStateNotifier
    _userStateNotifier = UserStateNotifier(widget.username);

    // Set user state to "online" when BasePage is created
    _userStateNotifier.setOnline();

    // Initialize pages
    _pages.add(
        UserDashboard(onSignOut: widget.onSignOut, username: widget.username));
    _pages.add(LearnWithUsPage());
    _pages.add(CommunityPage());
    _pages.add(MyActivitiesPage(username: widget.username));
    _pages.add(ProfilePage(username: widget.username));
  }

  @override
  void dispose() {
    // Remove observer when BasePage is disposed
    WidgetsBinding.instance.removeObserver(this);

    // Set user state to "offline" when BasePage is destroyed
    _userStateNotifier.setOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _userStateNotifier.setOffline();
    } else if (state == AppLifecycleState.resumed) {
      _userStateNotifier.setOnline();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pro Counsellor",
          style: TextStyle(color: Color(0xFFF0BB78)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _userStateNotifier
                  .setOffline(); // Explicitly set state to offline on logout
              widget.onSignOut();
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFFF0BB78),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb), label: "Learn with Us"),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Community"),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: "My Activities"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
