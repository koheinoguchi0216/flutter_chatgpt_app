import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';

import 'api_key.dart';

void main() {
  runApp(MyApp());
}

class Message {
  const Message(
    this.sendTime, {
    required this.message,
    required this.fromChatGpt,
  });

  final String message;
  final bool fromChatGpt;
  final DateTime sendTime;
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _MyHomePageState._colorBackground,
      ),
      home: const MyHomePage(title: 'Talk with GPT-3'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final openAI = OpenAI.instance.build(
    token: writeMyOpenAPIKey,
    enableLog: true,
  );

  final _textEditingController = TextEditingController();

  var _answer = '';

  final _messages = <Message>[
    Message(DateTime(2023, 7, 31, 10, 0, 0),
        message: 'こんにちは！', fromChatGpt: false),
    Message(DateTime(2023, 7, 31, 10, 0, 1),
        message: 'おはよう！今日はどんな予定があるの？', fromChatGpt: true),
    Message(DateTime(2023, 7, 31, 10, 0, 2),
        message: '今日は新しいプロジェクトの会議があるんだ。それから、夕方にはジムに行く予定だよ。君は？',
        fromChatGpt: false),
    Message(DateTime(2023, 7, 31, 10, 0, 3),
        message: 'お、新しいプロジェクト、楽しそう！僕は午後からフリーなので、友人とカフェに行く予定だよ。',
        fromChatGpt: true),
    Message(DateTime(2023, 7, 31, 10, 0, 4),
        message: 'いいね、楽しんできて！', fromChatGpt: false),
    Message(DateTime(2023, 7, 31, 10, 0, 5),
        message: 'ありがとう！会議、頑張ってね！', fromChatGpt: true),
    Message(DateTime(2023, 7, 31, 10, 0, 6),
        message: 'ありがとう！また後でチャットしよう！', fromChatGpt: false),
    Message(DateTime(2023, 7, 31, 10, 0, 7),
        message: '了解、また後で！', fromChatGpt: true),
  ];

  static const Color _colorBackground = Color.fromARGB(0xFF, 0x90, 0xac, 0xd7);
  static const Color _colorMyMessage = Color.fromARGB(0xFF, 0x8a, 0xe1, 0x7e);
  static const Color _colorOthersMessage =
      Color.fromARGB(0xFF, 0xff, 0xff, 0xff);
  static const Color _colorTime = Color.fromARGB(0xFF, 0x72, 0x88, 0xa8);
  static const Color _colorAvatar = Color.fromARGB(0xFF, 0x76, 0x5a, 0x44);

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                  child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: message.fromChatGpt
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.fromChatGpt)
                          SizedBox(
                              width: deviceWidth * 0.1,
                              child: CircleAvatar(
                                  backgroundColor: _colorAvatar,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Image.asset('images/openai.png'),
                                  ))),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!message.fromChatGpt)
                              Text(_formatDateTime(message.sendTime)),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                constraints:
                                    BoxConstraints(maxWidth: deviceWidth * 0.7),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: message.fromChatGpt
                                      ? _colorOthersMessage
                                      : _colorMyMessage,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    message.message,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            if (message.fromChatGpt)
                              Text(_formatDateTime(message.sendTime)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              )),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: _textEditingController,
                  )),
                  IconButton(
                      onPressed: () async {
                        final answer =
                            await _sendMessage(_textEditingController.text);
                        setState(() {
                          _answer = answer;
                        });
                      },
                      icon: const Icon(Icons.send)),
                ],
              ),
              Text(_answer),
            ],
          ),
        ));
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<String> _sendMessage(String message) async {
    final request = CompleteText(
      prompt: message,
      model: TextDavinci3Model(),
      maxTokens: 200,
    );

    final response = await openAI.onCompletion(request: request);
    return response!.choices.first.text;
  }
}
