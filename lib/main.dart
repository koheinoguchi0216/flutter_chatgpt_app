import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';

import 'api_key.dart';

void main() {
  runApp(MyApp());
}

class Message {
  const Message(
    this.imageUrl,
    this.sendTime, {
    required this.message,
    required this.fromChatGpt,
  });

  final String message;
  final bool fromChatGpt;
  final DateTime sendTime;
  final String imageUrl;

  Message.fromUser(String message, DateTime now)
      : this(message: '', '', DateTime.now(), fromChatGpt: false);

  Message.fromChatGpt(String message, DateTime now)
      : this(message: '', '', DateTime.now(), fromChatGpt: true);

  Message.image(String imageUrl, DateTime now)
      : this(message: '', imageUrl, DateTime.now(), fromChatGpt: true);

  Message.waitResponse(DateTime now)
      : this(message: '', '', DateTime.now(), fromChatGpt: true);
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

  final _textEditingController =
      TextEditingController(text: 'What is Flutter?');
  final _scrollController = ScrollController();

  bool _isLoading = false;
  final _messages = <Message>[];

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
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final showLoadingIcon =
                      _isLoading && index == _messages.length - 1;
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
                                  child: showLoadingIcon
                                      ? const CircularProgressIndicator()
                                      : message.imageUrl.isNotEmpty
                                          ? Image.network(message.imageUrl,
                                              frameBuilder: (BuildContext
                                                      context,
                                                  Widget child,
                                                  int? frame,
                                                  bool wasSynchronouslyLoaded) {
                                              if (!wasSynchronouslyLoaded) {
                                                _scrollDown();
                                              }
                                              return child;
                                            }, loadingBuilder:
                                                  (BuildContext context,
                                                      Widget child,
                                                      ImageChunkEvent?
                                                          loadingProgress) {
                                              if (loadingProgress != null) {
                                                return const CircularProgressIndicator();
                                              }
                                              return const CircularProgressIndicator();
                                            })
                                          : Text(
                                              message.message,
                                              style:
                                                  const TextStyle(fontSize: 16),
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
                      onPressed: () {
                        _isLoading
                            ? null
                            : _onTapSend(_textEditingController.text);
                      },
                      icon: Icon(Icons.send,
                          color: _isLoading ? Colors.grey : Colors.black)),
                  IconButton(
                      onPressed: () {
                        _isLoading
                            ? null
                            : _onTapImage(_textEditingController.text);
                      },
                      icon: Icon(Icons.image,
                          color: _isLoading ? Colors.grey : Colors.black)),
                ],
              ),
            ],
          ),
        ));
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _onTapSend(String userMessage) {
    setState(() {
      _isLoading = true;
      _messages.addAll([
        Message.fromUser(userMessage, DateTime.now()),
        Message.waitResponse(DateTime.now()),
      ]);
      _scrollDown();
    });

    _sendMessage(userMessage).then((chatGptMessage) {
      setState(() {
        _messages.last =
            Message.fromChatGpt(chatGptMessage.trim(), DateTime.now());
        _isLoading = false;
      });
      _scrollDown();
    });
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

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  void _onTapImage(String message) {
    setState(() {
      _isLoading = true;
      _messages.addAll([
        Message.fromUser(message, DateTime.now()),
        Message.waitResponse(DateTime.now()),
      ]);
      _scrollDown();
    });

    _generateImages(message, 2).then((urls) {
      setState(() {
        _messages.removeLast();
        _messages.addAll(urls.map((url) => Message.image(url, DateTime.now())));
        _isLoading = false;
      });
    });
  }

  Future<Iterable<String>> _generateImages(
      String message, int numOfImages) async {
    final request =
        GenerateImage(message, numOfImages, size: ImageSize.size256);
    final response = await openAI.generateImage(request);
    final imageList = response?.data ?? [];

    return imageList
        .where((e) => e != null && e.url != null)
        .map((e) => e!.url!);
  }
}
