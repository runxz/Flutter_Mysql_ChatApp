import 'package:flutter/material.dart';
import 'database_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatRoom {
  final String senderId;
  final String receiverId;

  ChatRoom({required this.senderId, required this.receiverId});
}

class ChatMessage {
  final String senderId;
  final String receiverId;
  final String message;

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.message,
  });
}

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<Map<String, String>> userList = [];

  Future<void> loadUserList() async {
    final conn = await getConnection();

    final results = await conn.query('SELECT * FROM users');

    userList = results.map((r) {
      final id = r['id'].toString();
      final username = r['username'].toString();
      return {'id': id, 'username': username};
    }).toList();

    await conn.close();

    print('User List: $userList'); // Debug statement

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadUserList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User List'),
      ),
      body: ListView.builder(
        itemCount: userList.length,
        itemBuilder: (context, index) {
          final username = userList[index]['username'];
          final receiverId = userList[index]['id'];

          return ListTile(
            title: Text(username!),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final String? senderId = prefs.getString('userId');
              // Create a chat room with the selected user
              final chatRoom = ChatRoom(
                senderId: senderId!,
                receiverId: receiverId!,
              );

              // Navigate to the chat room for the selected user
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatRoomScreen(chatRoom: chatRoom)),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  ChatRoomScreen({required this.chatRoom});

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  List<ChatMessage> chatMessages = [];
  TextEditingController messageController = TextEditingController();

  Future<void> loadChatMessages() async {
    final conn = await getConnection();

    final results = await conn.query(
      'SELECT sender_id, receiver_id, message FROM messages '
      'WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?) '
      'ORDER BY timestamp ASC',
      [
        widget.chatRoom.senderId,
        widget.chatRoom.receiverId,
        widget.chatRoom.receiverId,
        widget.chatRoom.senderId,
      ],
    );

    chatMessages = results
        .map((r) => ChatMessage(
              senderId: r['sender_id'].toString(),
              receiverId: r['receiver_id'].toString(),
              message: r['message'].toString(),
            ))
        .toList();

    await conn.close();

    setState(() {});
  }

  Future<void> sendMessage() async {
    final message = messageController.text.trim();

    if (message.isNotEmpty) {
      final conn = await getConnection();

      await conn.query(
        'INSERT INTO messages (sender_id, receiver_id, message, timestamp) '
        'VALUES (?, ?, ?, NOW())',
        [
          widget.chatRoom.senderId,
          widget.chatRoom.receiverId,
          message,
        ],
      );

      await conn.close();

      messageController.clear();
      loadChatMessages();
    }
  }

  @override
  void initState() {
    super.initState();
    loadChatMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Room'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final chatMessage = chatMessages[index];
                final isSentByMe =
                    chatMessage.senderId == widget.chatRoom.senderId;

                return ListTile(
                  title: Text(chatMessage.message),
                  subtitle: Text(isSentByMe ? 'Sent by me' : 'Received'),
                  tileColor: isSentByMe ? Colors.blue.withOpacity(0.3) : null,
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: sendMessage,
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
