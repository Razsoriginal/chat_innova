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

  @override
  void initState() {
    super.initState();
    _responseStreamController = StreamController<String>();
    _responseStream = _responseStreamController.stream;
    _sendRequest();
  }

  Future<void> _sendRequest() async {
    setState(() {
      data = false;
    });
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
          },
        ),
      );

      if (response.statusCode == 200) {
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
        });
      } else {
        throw Exception('Failed to fetch response: ${response.reasonPhrase}');
      }
    } catch (e) {
      _responseStreamController.addError(e);
    }
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
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: data
          ? Container(
              margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: const Color.fromARGB(255, 51, 51, 49)),
              child: ListTile(
                onTap: () {},
                leading: const Icon(Icons.file_present),
                title: const Text("Ask Anything"),
                trailing: const Icon(Icons.mic),
              ),
            )
          : null,
    );
  }
}
