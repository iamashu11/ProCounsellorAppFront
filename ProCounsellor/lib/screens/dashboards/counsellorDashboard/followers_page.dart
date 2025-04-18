import 'package:flutter/material.dart';
import '../../../services/api_utils.dart';
import 'client_details_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FollowersPage extends StatefulWidget {
  final String counsellorId;
  final Future<void> Function() onSignOut;

  FollowersPage({required this.counsellorId, required this.onSignOut});

  @override
  _FollowersPageState createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  List<dynamic> followers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchFollowers();
  }

  Future<void> fetchFollowers() async {
    final url = Uri.parse(
        '${ApiUtils.baseUrl}/api/counsellor/${widget.counsellorId}/followers');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          followers = json.decode(response.body) ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch followers")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Followers"),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Followers',
                      labelStyle: TextStyle(color: Colors.orange),
                      prefixIcon: Icon(Icons.search, color: Colors.orange),
                      fillColor: Color(0xFFFFF3E0),
                      filled: true,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                      ),
                      itemCount: followers
                          .where((follower) {
                            final name =
                                "${follower['firstName']} ${follower['lastName']}"
                                    .toLowerCase();
                            return name.contains(searchQuery);
                          })
                          .toList()
                          .length,
                      itemBuilder: (context, index) {
                        final filteredFollowers = followers.where((follower) {
                          final name =
                              "${follower['firstName']} ${follower['lastName']}"
                                  .toLowerCase();
                          return name.contains(searchQuery);
                        }).toList();

                        final follower = filteredFollowers[index];
                        final name =
                            "${follower['firstName']} ${follower['lastName']}";

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClientDetailsPage(
                                  client: follower,
                                  counsellorId: widget.counsellorId,
                                  onSignOut: widget.onSignOut,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: follower['photo'] != null &&
                                          follower['photo'].isNotEmpty
                                      ? Image.network(
                                          follower['photo'],
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/images/5857.jpg', // ✅ Asset fallback
                                              height: 80,
                                              width: 80,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        )
                                      : Image.asset(
                                          'assets/images/5857.jpg', // ✅ Local Asset Image
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
