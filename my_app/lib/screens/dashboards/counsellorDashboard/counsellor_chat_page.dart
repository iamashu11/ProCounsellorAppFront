import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/api_utils.dart';
import 'counsellor_chatting_page.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../optimizations/api_cache.dart';

class ChatsPage extends StatefulWidget {
  final String counsellorId;
  final Future<void> Function() onSignOut;

  ChatsPage({required this.counsellorId, required this.onSignOut});

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> filteredChats = [];
  bool isLoading = true;
  String searchQuery = '';
  late DatabaseReference chatRef;

  @override
  void initState() {
    super.initState();
    fetchChats();
    _listenToRealtimeMessages();
  }

  Future<void> fetchChats() async {
    try {
      String cacheKey = "chats_${widget.counsellorId}";
      String apiUrl =
          "${ApiUtils.baseUrl}/api/counsellor/${widget.counsellorId}/clients";

      // ✅ Step 1: Check Cache First
      var cachedChats = await ApiCache.get(cacheKey);
      if (cachedChats != null) {
        print("✅ Loaded chat list from cache");
        _updateChatList(cachedChats);
      }

      // ✅ Step 2: Fetch Data from API
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> clients = json.decode(response.body);

        List<Future<Map<String, dynamic>?>> chatFutures =
            clients.map((client) async {
          final userId = client['userName'];
          final clientName = "${client['firstName']} ${client['lastName']}";
          final clientPhotoUrl =
              client['photo'] ?? 'https://via.placeholder.com/150';

          try {
            // ✅ Check if chat exists
            final chatExistsResponse = await http.get(Uri.parse(
                '${ApiUtils.baseUrl}/api/chats/exists?userId=$userId&counsellorId=${widget.counsellorId}'));

            if (chatExistsResponse.statusCode == 200 &&
                json.decode(chatExistsResponse.body) == true) {
              // ✅ Start or fetch existing chat
              final chatResponse = await http.post(Uri.parse(
                  '${ApiUtils.baseUrl}/api/chats/start-chat?userId=$userId&counsellorId=${widget.counsellorId}'));

              if (chatResponse.statusCode == 200) {
                final chatData = json.decode(chatResponse.body);
                final chatId = chatData['chatId'];

                // ✅ Fetch chat messages
                final messagesResponse = await http.get(
                  Uri.parse('${ApiUtils.baseUrl}/api/chats/$chatId/messages'),
                );

                if (messagesResponse.statusCode == 200) {
                  final messages =
                      json.decode(messagesResponse.body) as List<dynamic>;

                  return _processChatData(
                      chatId, userId, clientName, clientPhotoUrl, messages);
                }
              }
            }
          } catch (e) {
            print("Error fetching chat for user $userId: $e");
          }
          return null;
        }).toList();

        // ✅ Wait for all chat data to be processed
        final chatDetails = await Future.wait(chatFutures);

        // ✅ Store updated chats in cache
        await ApiCache.set(cacheKey, chatDetails, persist: true);

        // ✅ Update UI with latest chat data
        _updateChatList(chatDetails);
      } else {
        throw Exception("Failed to fetch chatting clients");
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

  Map<String, dynamic> _processChatData(String chatId, String userId,
      String clientName, String clientPhotoUrl, List<dynamic> messages) {
    String lastMessage = 'No messages yet';
    String timestamp = 'N/A';
    bool isSeen = true;
    String senderId = '';

    if (messages.isNotEmpty) {
      var lastMsg = messages.last;
      senderId = lastMsg['senderId'] ?? '';

      if (lastMsg.containsKey('text') && lastMsg['text'] != null) {
        lastMessage = lastMsg['text'];
      } else if (lastMsg.containsKey('fileUrl') && lastMsg['fileUrl'] != null) {
        String fileType = lastMsg['fileType'] ?? 'unknown';

        if (fileType.startsWith('image/')) {
          lastMessage = "📷 Image";
        } else if (fileType.startsWith('video/')) {
          lastMessage = "🎥 Video";
        } else {
          lastMessage = "📄 File";
        }
      }

      timestamp = DateFormat('dd MMM yyyy, h:mm a').format(
        DateTime.fromMillisecondsSinceEpoch(lastMsg['timestamp']),
      );
      isSeen = lastMsg['isSeen'] ?? true;
    }

    return {
      'id': chatId,
      'userId': userId,
      'name': clientName,
      'photoUrl': clientPhotoUrl,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'isSeen': isSeen,
      'senderId': senderId,
    };
  }

  void _updateChatList(List<dynamic> chatDetails) {
    setState(() {
      chats = chatDetails.whereType<Map<String, dynamic>>().toList();
      chats.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      filteredChats = List.from(chats);
      isLoading = false;
    });
  }

  void _listenToRealtimeMessages() {
    chatRef = FirebaseDatabase.instance.ref('chats');

    chatRef.onChildChanged.listen((event) {
      if (event.snapshot.value != null) {
        final chatId = event.snapshot.key;
        final updatedChatData =
            Map<String, dynamic>.from(event.snapshot.value as Map);

        if (chatId != null && updatedChatData.containsKey('messages')) {
          final messages =
              Map<String, dynamic>.from(updatedChatData['messages']);
          if (messages.isNotEmpty) {
            final lastMessageKey = messages.keys.last;
            final lastMessageData = messages[lastMessageKey];

            final index = chats.indexWhere((chat) => chat['id'] == chatId);
            if (index != -1) {
              setState(() {
                chats[index]['lastMessage'] =
                    lastMessageData['text'] ?? 'No message';
                chats[index]['timestamp'] =
                    DateFormat('dd MMM yyyy, h:mm a').format(
                  DateTime.fromMillisecondsSinceEpoch(
                      lastMessageData['timestamp']),
                );
                chats[index]['isSeen'] = lastMessageData['isSeen'] ?? true;
                chats[index]['senderId'] = lastMessageData['senderId'] ?? '';

                // Move updated chat to the top
                final updatedChat = chats.removeAt(index);
                chats.insert(0, updatedChat);
                filteredChats = List.from(chats);

                // ✅ Update Cache with Latest Messages
                String cacheKey = "chats_${widget.counsellorId}";
                ApiCache.set(cacheKey, chats, persist: true);
              });
            } else {
              print("⚠️ Chat ID Not Found in List: $chatId");
            }
          } else {
            print("⚠️ No messages found in Chat ID: $chatId");
          }
        }
      }
    });
  }

  void filterChats(String query) {
    setState(() {
      searchQuery = query;
      filteredChats = chats
          .where((chat) => chat['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "My Chats",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterChats,
              decoration: InputDecoration(
                hintText: "Search clients...",
                prefixIcon: Icon(Icons.search, color: Colors.orange),
                fillColor: Color(0xFFFFF3E0),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: Colors.deepOrangeAccent,
                      size: 50,
                    ),
                  )
                : filteredChats.isEmpty
                    ? Center(child: Text("No chats available"))
                    : ListView.separated(
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                          indent: 10,
                          endIndent: 10,
                        ),
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          final name = chat['name'] ?? 'Unknown Client';
                          final photoUrl = chat['photoUrl'];
                          final userId = chat['userId'];
                          final lastMessage = chat['lastMessage'];
                          final timestamp = chat['timestamp'];
                          final isSeen = chat['isSeen'];
                          final senderId = chat['senderId'];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChattingPage(
                                    itemName: name,
                                    userId: userId,
                                    counsellorId: widget.counsellorId,
                                    photo: photoUrl,
                                    onSignOut: widget.onSignOut,
                                  ),
                                ),
                              ).then((_) {
                                fetchChats(); // Refresh chats after returning
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundColor:
                                        Colors.grey[300], // Placeholder color
                                    backgroundImage: NetworkImage(photoUrl),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              timestamp,
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                lastMessage,
                                                style: TextStyle(
                                                  fontSize: 14.0,
                                                  color: Colors.grey[600],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (!isSeen &&
                                                senderId != widget.counsellorId)
                                              Icon(
                                                Icons.circle,
                                                color: Colors.blue,
                                                size: 10,
                                              ),
                                          ],
                                        ),
                                      ],
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
    );
  }
}
