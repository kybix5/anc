import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';

class MessageWidget extends StatefulWidget {
  const MessageWidget({super.key});

  @override
  _MessageWidgetState createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  String deviceId = 'unknown';

  final TextEditingController _controller = TextEditingController();

  final String _key = 'my32lengthsupersecretnooneknows1'; // 32 байта
  List<String> messages = [];
  List<String> sender = [];
  List<String> created = [];
  final ScrollController _scrollController = ScrollController();

  Future getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor.toString();
    }
    print('Device ID: $deviceId');
  }

  void _sendMessage(String message) async {
    if (message.isEmpty) return; 
    const senderIn = 'Вы';
    final createdAt = DateTime.now().toIso8601String().split('.')[0];
    final iv = encrypt.IV.fromLength(16);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(_key)));

    final encrypted = encrypter.encrypt(message, iv: iv);

    await http.post(
      Uri.parse('https://anchih.e-rec.ru/api/store_message.php'),
      body: json.encode({
        'message': encrypted.base64,
        'iv': iv.base64,
        'sender': deviceId,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (!mounted) return;

    setState(() {
      sender.add(senderIn);
      messages.add(message);
      created.add(createdAt);
    });

    // ⚠ Проверяем наличие элементов перед прокруткой
    _scrollToBottom();
  }

  void _fetchMessages() async {
    final response = await http
        .get(Uri.parse('https://anchih.e-rec.ru/api/get_messages.php'));

    if (!mounted) return;

    if (response.statusCode == 200) {
      final List<dynamic> jsonMessages = json.decode(response.body);

      // ⚠ Если сообщений нет, вызываем setState для Center
      if (jsonMessages.isEmpty) {
        print('Сообщений нет');
        if (!mounted) return;
        setState(() {});
        return;
      }

      for (var jsonMessage in jsonMessages) {
        final iv = encrypt.IV.fromBase64(jsonMessage['iv']);
        final encryptedMessage = jsonMessage['message'];
        final senderIn = jsonMessage['sender'];
        final createdAt = jsonMessage['created_at'];

        final encrypter =
            encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(_key)));

        try {
          final decrypted = encrypter.decrypt64(encryptedMessage, iv: iv);

          if (!mounted) return;

          setState(() {
            sender.add(senderIn == deviceId ? "вы" : senderIn);
            messages.add(decrypted);
            created.add(createdAt);
          });
        } catch (e) {
          print('Ошибка дешифрования: $e');
        }
      }

      // ⚠ Прокрутка вниз только если есть элементы
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } else {
      print('Ошибка сервера: ${response.statusCode}');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && messages.isNotEmpty) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ⚠ Асинхронные вызовы оставляем как есть
    getDeviceId();
    _fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сообщения')),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Нет сообщений'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        child: ListTile(
                          title: Text(
                            sender[index],
                            style:
                                const TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                messages[index],
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  created[index],
                                  style: const TextStyle(
                                      fontSize: 8, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {},
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: 'Введите сообщение..'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
