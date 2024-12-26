import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'counsellor_chatting_page.dart';

class ChatsPage extends StatefulWidget {
  final String counsellorId;

  ChatsPage({required this.counsellorId});

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<dynamic> clients = [];
  List<dynamic> filteredClients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChattingClients();
  }

  Future<void> fetchChattingClients() async {
    final url = Uri.parse(
        'http://localhost:8080/api/counsellor/${widget.counsellorId}/clients');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> allClients = json.decode(response.body);

        // Filter clients based on the second API
        List<dynamic> chattingClients = [];
        for (var client in allClients) {
          final chatExistsUrl = Uri.parse(
              'http://localhost:8080/api/chats/exists?userId=${client['userName']}&counsellorId=${widget.counsellorId}');
          final chatExistsResponse = await http.get(chatExistsUrl);

          if (chatExistsResponse.statusCode == 200 &&
              json.decode(chatExistsResponse.body) == true) {
            chattingClients.add(client);
          }
        }

        setState(() {
          clients = chattingClients;
          filteredClients = chattingClients; // Initialize filtered list
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch clients")),
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

  void filterClients(String query) {
    setState(() {
      filteredClients = clients
          .where((client) => "${client['firstName']} ${client['lastName']}"
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Search Clients",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: filterClients,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            client['photo'] ??
                                'https://via.placeholder.com/150',
                          ),
                        ),
                        title: Text(
                            "${client['firstName']} ${client['lastName']}"),
                        subtitle: Text("Email: ${client['email']}"),
                        onTap: () {
                          // Navigate to ChattingPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChattingPage(
                                itemName:
                                    "${client['firstName']} ${client['lastName']}",
                                userId: client['userName'],
                                counsellorId: widget.counsellorId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}