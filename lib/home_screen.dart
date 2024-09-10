import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Socket socket;
  final todosStream = StreamController<List<Map<String, dynamic>>>();
  final controller = TextEditingController();
  List<Map<String, dynamic>> todos = [];

  @override
  void initState() {
    super.initState();
    connectToServer();
  }

  void connectToServer() {
    // Connect to the Node.js server
    String url = 'https://515f-89-236-218-41.ngrok-free.app/';
    // int port = 3000;
    // if (Platform.isAndroid) {
    //   url = 'https://515f-89-236-218-41.ngrok-free.app/';
    // }
    socket = io(url, {
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();

    // Listen for updated todos from the server
    socket.on('todos', (data) {
      todos = List<Map<String, dynamic>>.from(data);
      todosStream.add(todos);
    });

    // Handle connection
    socket.onConnect((_) {
      print('connected to server');
    });

    // Handle disconnection
    socket.onDisconnect((_) {
      print('disconnected from server');
    });
  }

  void addTodo() {
    String todo = controller.text;
    if (todo.isNotEmpty) {
      socket.emit('add_todo', todo); // Send new todo to the server
      controller.clear();
    }
  }

  void removeTodoAtIndex(int index) {
    socket.emit('remove_todo', index); // Send removal request to server
  }

  void toggleTodoAtIndex(int index) {
    socket.emit('toggle_todo', index); // Send toggle request to server
  }

  @override
  void dispose() {
    socket.dispose();
    controller.dispose();
    todosStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Enter Todo',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addTodo,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: todosStream.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(snapshot.error.toString()),
                    );
                  }

                  final t = snapshot.data;

                  if (t == null) {
                    return const Center(
                      child: Text("No data"),
                    );
                  }

                  return ListView.builder(
                    itemCount: t.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          t[index]['text'],
                          style: TextStyle(
                            decoration: t[index]['completed']
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            removeTodoAtIndex(index);
                          },
                        ),
                        onTap: () {
                          toggleTodoAtIndex(index); // Toggle completion on tap
                        },
                      );
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }
}
