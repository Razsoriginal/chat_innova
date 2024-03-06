import 'package:chat_innova/constant/colors.dart';
import 'package:flutter/material.dart';

import 'chatPage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 31, 29),
        leading: const Icon(Icons.account_circle_outlined, color: Colors.white),
        title: const Text("Chat Innova"),
        centerTitle: true,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(Icons.share),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Center(
            child: Text(
              "Where Knowledge begins",
              style: TextStyle(fontSize: 20),
            ),
          ),
          Positioned(
            bottom: 20.0,
            left: 20.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: const Color.fromARGB(255, 51, 51, 49)),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatPage()),
                  );
                },
                leading: const Icon(Icons.file_present),
                title: const Text("Ask Anything"),
                trailing: const Icon(Icons.mic),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 31, 31, 29),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assistant),
            label: "Channels",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_library_outlined),
            label: "Library",
          ),
        ],
      ),
    );
  }
}
