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
    //String? deviceId;

    // Получаем информацию о платформе
    if (Theme.of(context).platform == TargetPlatform.android) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      String dev = androidInfo.toString();
      //print(dev);
      deviceId = androidInfo.id;
      // Уникальный идентификатор для Android
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor
          .toString(); // Уникальный идентификатор для iOS
    }
    print('Device ID: $deviceId');
  }

  void _sendMessage(String message) async {
    if (message.isEmpty) return; // Проверка на пустое сообщение
    const senderIn = 'Вы';
    final createdAt = DateTime.now().toIso8601String().split('.')[0];
    final iv = encrypt.IV.fromLength(16);
    //final iv = IV.fromSecureRandom(16);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(_key)));

    // Шифрование сообщения
    final encrypted = encrypter.encrypt(message, iv: iv);

    print(encrypted.base64);
    print('--');
    print(iv.base64);

    // getDeviceId();

    // Отправка на сервер
    await http.post(
      Uri.parse('https://anchih.e-rec.ru/api/store_message.php'),
      body: json.encode({
        'message': encrypted.base64,
        'iv': iv.base64,
        'sender': deviceId,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    setState(() {
      sender.add(senderIn);
      messages.add(message);
      created.add(createdAt);
    });

    // Прокрутка вниз к последнему сообщению
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    // Прокрутка вниз после отправки сообщения
    _scrollToBottom();
  }

  void _fetchMessages() async {
    final response = await http
        .get(Uri.parse('https://anchih.e-rec.ru/api/get_messages.php'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonMessages = json.decode(response.body);
      for (var jsonMessage in jsonMessages) {
        final iv = encrypt.IV.fromBase64(jsonMessage['iv']);
        final encryptedMessage = jsonMessage['message'];
        final senderIn = jsonMessage['sender'];
        final createdAt = jsonMessage['created_at'];

        // Дешифрование сообщения
        final encrypter =
            encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(_key)));
        //final decrypted = encrypter.decrypt64(encryptedMessage, iv: iv);

        try {
          final decrypted = encrypter.decrypt64(encryptedMessage, iv: iv);
          setState(() {
            //если автором являеться это устройство то отмечаем
            if (senderIn == deviceId) {
              sender.add("вы");
            } else {
              sender.add(senderIn);
            }
            messages.add(decrypted);
            created.add(createdAt);
          });
        } catch (e) {
          print('Ошибка дешифрования: $e');
        }
      }
    }

    // Прокрутка вниз после завершения всех обновлений состояния
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

/*
  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }
*/
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchMessages();
    getDeviceId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сообшения')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  messages[index], // Время
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '', // Время
                                style:
                                    TextStyle(fontSize: 8, color: Colors.grey),
                              ),
                              Text(
                                created[index], // Дата
                                style: const TextStyle(
                                    fontSize: 8, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {},
                    ),
                  );
                }),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Введите сообщение..'),
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
    super.dispose();
  }
}
