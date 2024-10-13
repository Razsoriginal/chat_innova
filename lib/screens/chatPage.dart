import 'dart:convert';

import 'package:chat_innova/constant/colors.dart';
import 'package:chat_innova/screens/threadPage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool isWeb = false;
  String selectedOption = 'General chat';
  final TextEditingController _textEditingController = TextEditingController();
  bool isTyping = false;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      if (_textEditingController.text.isNotEmpty) {
        isTyping = true;
      } else {
        isTyping = false;
      }
    });
  }

  void _pickFile() async {
    // Request storage permission
    var status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      // Permission granted, proceed with file picking
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(withData: true);
      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
        print(_selectedFile?.name);
        // Handle the picked file here

        _sendFileAndMessage();
      }
    } else {
      // Permission denied, show a message to the user
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Permission Required'),
          content: Text('Please grant storage permission to pick files.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void updateSelectedOption(String option) {
    setState(() {
      selectedOption = option;
    });
  }

  void _sendFileAndMessage() async {
    String apiUrl = 'http://localhost:8000/chat_api/';

    try {
      // Create a multipart request
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add user query as a field
      request.fields['user_query'] = _textEditingController.text;

      // Add file as a part of the request
      var bytes = _selectedFile!.bytes?.toList();
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes!,
            filename: _selectedFile?.name),
      );

      // Send the request
      var streamedResponse = await request.send();

      // Decode the response
      var response = await streamedResponse.stream.bytesToString();
      var responseData = json.decode(response);

      // Return the response data
      print(responseData);
      return responseData;
    } catch (e) {
      // Handle error
      print('Error: $e');
    }
  }

  void _sendMessage() {
    FocusScope.of(context).unfocus();
    String messageText = _textEditingController.text;
    String focusText = selectedOption;
    bool isWebSearch = isWeb;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ThreadPage(
          messageText: messageText,
          focusText: focusText,
          isWebSearch: isWebSearch,
          file: _selectedFile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1,
            color: Colors.grey,
            thickness: 0.5,
          ),
        ),
        backgroundColor: backgroundColor,
        leading: InkWell(
          child: const Icon(Icons.arrow_back_outlined),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("New Thread"),
        actions: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => FocusBottomSheet(
                    selectedOption: selectedOption,
                    updateSelectedOption: updateSelectedOption),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Text(
                    selectedOption == "General chat" ? "Focus" : selectedOption,
                    style: const TextStyle(fontSize: 20, color: primaryColor),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    selectedOption == "General chat"
                        ? Icons.search
                        : selectedOption == "Academic"
                            ? Icons.school_outlined
                            : selectedOption == "Writing"
                                ? Icons.create_outlined
                                : selectedOption == "Youtube"
                                    ? Icons.video_library_outlined
                                    : Icons.error_outline,
                    // Default icon if none of the conditions match
                    color: primaryColor,
                  ),
                  const SizedBox(width: 10)
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: inputBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5, right: 5, left: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _textEditingController,
                      // Assign the TextEditingController
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: "Ask anything...",
                        hintStyle: TextStyle(color: textBg, fontSize: 20),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pickFile,
                              // Call _pickFile when the plus icon is tapped
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: iconBg,
                                ),
                                padding: const EdgeInsets.all(5.0),
                                child:
                                    const Icon(Icons.add, color: Colors.white),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Switch(
                              inactiveTrackColor: iconBg,
                              inactiveThumbColor: primaryColor,
                              value: isWeb,
                              onChanged: (value) {
                                setState(() {
                                  isWeb = value;
                                });
                              },
                              activeColor: primaryColor,
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  isWeb = !isWeb;
                                });
                              },
                              child: Text(
                                'Search Web',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: isWeb ? Colors.blue : textBg),
                              ),
                            ),
                          ],
                        ),
                        isTyping
                            ? GestureDetector(
                                onTap: _sendMessage,
                                child:
                                    const Icon(Icons.send, color: primaryColor),
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: iconBg,
                                ),
                                padding: const EdgeInsets.all(5.0),
                                child:
                                    const Icon(Icons.mic, color: Colors.white),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FocusBottomSheet extends StatelessWidget {
  final void Function(String) updateSelectedOption;
  String selectedOption;

  FocusBottomSheet({
    super.key,
    required this.selectedOption,
    required this.updateSelectedOption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: focusSheet,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 5,
                width: 50,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const Text(
              '🔍 Search',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              title: const Text("All"),
              subtitle:
                  const Text("Search across  the internet and other focuses"),
              onTap: () {
                updateSelectedOption("General chat");
                Navigator.pop(context);
              },
              trailing: selectedOption == "General chat"
                  ? const Icon(Icons.check)
                  : null,
            ),
            const Divider(),
            ListTile(
              title: const Text("Academic"),
              subtitle: const Text("Search in published academic papers"),
              onTap: () {
                updateSelectedOption("Academic");
                Navigator.pop(context);
              },
              trailing:
                  selectedOption == "Academic" ? const Icon(Icons.check) : null,
            ),
            const Divider(),
            ListTile(
              title: const Text("Writing"),
              subtitle: const Text("For generating text and code"),
              onTap: () {
                updateSelectedOption("Writing");
                Navigator.pop(context);
              },
              trailing:
                  selectedOption == "Writing" ? const Icon(Icons.check) : null,
            ),
            const Divider(),
            ListTile(
              title: const Text("Youtube"),
              subtitle: const Text("Chat with youtube videos"),
              onTap: () {
                updateSelectedOption("Youtube");
                Navigator.pop(context);
              },
              trailing:
                  selectedOption == "Youtube" ? const Icon(Icons.check) : null,
            ),
          ],
        ),
      ),
    );
  }
}
