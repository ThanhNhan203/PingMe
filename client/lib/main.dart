import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SocketDemoPage(),
    );
  }
}

class SocketDemoPage extends StatefulWidget {
  @override
  _SocketDemoPageState createState() => _SocketDemoPageState();
}

class _SocketDemoPageState extends State<SocketDemoPage> {
  late IO.Socket socket;
  List<Map<String, String>> chatHistory = [];
  TextEditingController messageController = TextEditingController();
  TextEditingController receiverController = TextEditingController();
  String? clientId;

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  void initSocket() {
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.onConnect((_) {
      print('Connected to server');
      clientId = socket.id;
      print('Your client ID: $clientId');
    });

    socket.on('private-message', (data) {
      setState(() {
        chatHistory
            .add({'senderId': data['senderId'], 'message': data['message']});
      });
    });

    socket.on('chat-history', (data) {
      setState(() {
        chatHistory = List<Map<String, String>>.from(data);
      });
    });

    socket.onDisconnect((_) => print('Disconnected from server'));
  }

  void sendMessage() {
    String text = messageController.text.trim();
    String receiverId = receiverController.text.trim();

    if (text.isNotEmpty && receiverId.isNotEmpty) {
      socket.emit('private-message', {
        'receiverId': receiverId,
        'message': text,
      });
      messageController.clear();
    }
  }

  void loadChatHistory() {
    String receiverId = receiverController.text.trim();
    if (receiverId.isNotEmpty) {
      socket.emit('get-chat-history', receiverId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Socket.IO Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SelectableText(
              'Your Client ID: ${clientId ?? "Connecting..."}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = chatHistory[index];
                  bool isSentByMe = chat['senderId'] == clientId;
                  return Align(
                    alignment: isSentByMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSentByMe ? Colors.blue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(chat['message']!),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: receiverController,
                    decoration: InputDecoration(
                      labelText: 'Receiver ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Enter your message',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        sendMessage(); // Gửi tin nhắn khi nhấn Enter
                      }
                    },
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: sendMessage,
                  child: Text('Send'),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: loadChatHistory,
              child: Text('Load Chat History'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket.dispose();
    messageController.dispose();
    receiverController.dispose();
    super.dispose();
  }
}
