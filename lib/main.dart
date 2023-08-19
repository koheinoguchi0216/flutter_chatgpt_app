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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                  return Row(
                    children: [
                      const CircleAvatar(radius: 16, child: Icon(Icons.add)),
                      ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: deviceWidth * 0.7),
                          child: Text(_messages[index].message)),
                      const Text('午前12:00')
                    ],
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
