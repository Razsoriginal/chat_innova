import 'dart:convert';

import 'package:chat_innova/constant/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;

class ThreadPage extends StatefulWidget {
  final String messageText;
  final String focusText;
  final bool isWebSearch;
  final PlatformFile? file;

  const ThreadPage({
    Key? key,
    required this.messageText,
    required this.focusText,
    required this.isWebSearch,
    this.file,
  }) : super(key: key);

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  bool isWeb = false;
  final TextEditingController _textEditingController = TextEditingController();
  List<Map<String, String>> chatHistory = [];
  late bool isWaitingForResponse;
  late ScrollController _scrollController;
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(_onTextChanged);
    _addUserQueryToChatHistory(widget.messageText);
    _sendRequest(widget.messageText);
    _scrollController = ScrollController();
    isWaitingForResponse = true;
    setState(() {
      isWeb = widget.isWebSearch;
    });
  }

  void _onTextChanged() {
    setState(() {
      isTyping = _textEditingController.text.isNotEmpty;
    });
  }

  void _addUserQueryToChatHistory(String query) {
    chatHistory.add({'role': 'user', 'content': query});
  }

  Future<void> _sendRequest(String message) async {
    try {
      final url = Uri.parse('http://localhost:8000/innova_ai/');
      final Map<String, dynamic> requestBody = {
        'msg': message,
        'focus': widget.focusText,
        'isWeb': isWeb.toString(),
        'chatHistory': chatHistory,
      };

      // Add file to request body if available
      if (widget.file != null) {
        requestBody['file'] = widget.file!.bytes;
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (kDebugMode) {
          print('Response Body: $responseBody');
        }
        _addAssistantResponseToChatHistory(responseBody);
      } else {
        throw Exception('Failed to fetch response: ${response.reasonPhrase}');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
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

  void _addAssistantResponseToChatHistory(String response) {
    setState(() {
      chatHistory.add({'role': 'assistant', 'content': response});
      isWaitingForResponse = false;
    });

    // Scroll to the end of the chat history
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage(String message) {
    _addUserQueryToChatHistory(message);
    _sendRequest(message);
    _textEditingController.clear();
    FocusScope.of(context).unfocus(); // Hide the keyboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text('Thread'),
        actions: const [
          Icon(Icons.share),
          SizedBox(
            width: 5,
          ),
          Icon(Icons.more_vert),
          SizedBox(
            width: 15,
          )
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var chat in chatHistory)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (chat['role'] == 'user')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 15,
                              ),
                              Text(
                                chat['content']!,
                                style: const TextStyle(fontSize: 33),
                              ), // user query
                              const SizedBox(height: 13),
                              const Row(
                                children: [
                                  Icon(Icons.air),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    "Answer",
                                    style: TextStyle(fontSize: 23),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                        if (chat['role'] == 'assistant')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isWaitingForResponse)
                                const SpinKitThreeInOut(
                                  color: Colors.blue,
                                  size: 30.0,
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MarkdownBody(
                                      data: chat['content']!,
                                      selectable: true,
                                      styleSheet: MarkdownStyleSheet(
                                        p: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.share),
                                            SizedBox(width: 15),
                                            Icon(Icons.refresh),
                                            SizedBox(width: 15),
                                            Icon(Icons.copy_rounded),
                                          ],
                                        ),
                                        Icon(Icons.more_vert),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                      ],
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height / 20,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: inputBg,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      child: Padding(
                        padding:
                            const EdgeInsets.only(bottom: 5, right: 5, left: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              onTap: () {},
                              controller: _textEditingController,
                              decoration: const InputDecoration(
                                hintText: "Ask anything...",
                                hintStyle:
                                    TextStyle(color: textBg, fontSize: 20),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: iconBg,
                                      ),
                                      padding: const EdgeInsets.all(5.0),
                                      child: const Icon(Icons.add,
                                          color: Colors.white),
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
                                            color:
                                                isWeb ? Colors.blue : textBg),
                                      ),
                                    ),
                                  ],
                                ),
                                isTyping
                                    ? GestureDetector(
                                        onTap: () => _sendMessage(
                                            _textEditingController.text),
                                        child: const Icon(Icons.send,
                                            color: primaryColor),
                                      )
                                    : Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: iconBg,
                                        ),
                                        padding: const EdgeInsets.all(5.0),
                                        child: const Icon(Icons.mic,
                                            color: Colors.white),
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
            ],
          ),
        ),
      ),
    );
  }
}
