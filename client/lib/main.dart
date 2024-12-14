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
  String message = "No messages yet";
  TextEditingController messageController = TextEditingController();

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
    });

    socket.on('message', (data) {
      print('Message from server: $data');
      setState(() {
        message = data;
      });
    });

    socket.onDisconnect((_) => print('Disconnected from server'));
  }

  void sendMessage() {
    String text = messageController.text.trim();
    if (text.isNotEmpty) {
      socket.emit('message', text);
      messageController.clear(); // Clear input field
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
            Expanded(
              child: Center(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Enter your message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: sendMessage,
                  child: Text('Send'),
                ),
              ],
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
    super.dispose();
  }
}
