import 'dart:async';
import 'dart:convert';

import 'package:chat_innova/constant/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;

class ThreadPage extends StatefulWidget {
  final String messageText;
  final String focusText;
  final bool isWebSearch;

  const ThreadPage({
    super.key,
    required this.messageText,
    required this.focusText,
    required this.isWebSearch,
  });

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  late StreamController<String> _responseStreamController;
  late Stream<String> _responseStream;
  bool data = false;
  bool isLoading = true;

  bool isWeb = false;
  String selectedOption = 'General chat';
  final TextEditingController _textEditingController = TextEditingController();
  bool isTyping = false;
  List<Map<String, String>> chatHistory = [];

  @override
  void initState() {
    super.initState();
    _responseStreamController = StreamController<String>();
    _responseStream = _responseStreamController.stream;
    _textEditingController.addListener(_onTextChanged);
    _sendFirstRequest();
  }

  void _onTextChanged() {
    setState(() {
      isTyping = _textEditingController.text.isNotEmpty;
    });
  }

  Future<void> _sendFirstRequest() async {
    try {
      final String isWeb = widget.isWebSearch.toString();
      final url = Uri.parse('http://localhost:8000/innova_ai/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          {
            'msg': widget.messageText,
            'focus': widget.focusText,
            'isWeb': isWeb,
            'chatHistory': chatHistory
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          chatHistory.add({
            'role': 'user',
            'content': widget.messageText,
          });
        });
        final responseBody = response.body;
        if (kDebugMode) {
          print('Response Body: $responseBody');
        }
        final responseStream = Stream.periodic(
          const Duration(milliseconds: 100),
          (_) => responseBody.substring(0, responseBody.length),
        );
        _responseStreamController.addStream(responseStream);
        setState(() {
          data = true;
          isLoading = false;
          chatHistory.add({'role': 'assistant', 'content': responseBody});
        });
      } else {
        throw Exception('Failed to fetch response: ${response.reasonPhrase}');
      }
    } catch (e) {
      _responseStreamController.addError(e);
    }
  }

  Future<void> _sendRequest() async {
    FocusScope.of(context).unfocus();
    String messageText = _textEditingController.text;
    String focusText = selectedOption;
    String isWebSearch = isWeb.toString();
    try {
      final url = Uri.parse('http://localhost:8000/innova_ai/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          {
            'msg': messageText,
            'focus': focusText,
            'isWeb': isWebSearch,
            'chatHistory': chatHistory
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          chatHistory.add({
            'role': 'user',
            'content': widget.messageText,
          });
        });
        final responseBody = response.body;
        if (kDebugMode) {
          print('Response Body: $responseBody');
        }
        final responseStream = Stream.periodic(
          const Duration(milliseconds: 100),
          (_) => responseBody.substring(0, responseBody.length),
        );
        _responseStreamController.addStream(responseStream);
        setState(() {
          data = true;
          isLoading = false;
          chatHistory.add({'role': 'assistant', 'content': responseBody});
        });
      } else {
        throw Exception('Failed to fetch response: ${response.reasonPhrase}');
      }
    } catch (e) {
      _responseStreamController.addError(e);
    }
  }

  void _sendMessage() {
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
    });
    _sendRequest();
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AiChat(widget: widget, responseStream: _responseStream),
              Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height / 2.7),
                child: queryInput(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Container queryInput() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: inputBg,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5, right: 5, left: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              onTap: () {},
              controller: _textEditingController,
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
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconBg,
                      ),
                      padding: const EdgeInsets.all(5.0),
                      // Adjust padding as needed
                      child: const Icon(Icons.add, color: Colors.white),
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
                            fontSize: 20, color: isWeb ? Colors.blue : textBg),
                      ),
                    ),
                  ],
                ),
                isTyping
                    ? GestureDetector(
                        onTap: _sendMessage,
                        child: const Icon(Icons.send, color: primaryColor),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconBg,
                        ),
                        padding: const EdgeInsets.all(5.0),
                        child: const Icon(Icons.mic, color: Colors.white),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AiChat extends StatelessWidget {
  const AiChat({
    super.key,
    required this.widget,
    required Stream<String> responseStream,
  }) : _responseStream = responseStream;

  final ThreadPage widget;
  final Stream<String> _responseStream;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 15,
        ),
        Text(
          widget.messageText,
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
        StreamBuilder<String>(
          stream: _responseStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return MarkdownBody(
                data: snapshot.data!,
                selectable: true,
                styleSheet:
                    MarkdownStyleSheet(p: const TextStyle(fontSize: 18)),
              ); // AI Answer
            } else if (snapshot.hasError) {
              return Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(fontSize: 18),
              );
            } else {
              return const SpinKitThreeInOut(
                color: primaryColor,
                size: 30.0,
              );
            }
          },
        ),
        const SizedBox(
          height: 12,
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.share),
                SizedBox(width: 15),
                Icon(Icons.refresh),
                SizedBox(
                  width: 15,
                ),
                Icon(Icons.copy_rounded)
              ],
            ),
            Icon(Icons.more_vert)
          ],
        ),
      ],
    );
  }
}
