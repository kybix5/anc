import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Тест сообщений',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MessageWidget(),
    );
  }
}

class MessageWidget extends StatefulWidget {
  const MessageWidget({super.key});

  @override
  _MessageWidgetState createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  String deviceId = 'unknown';
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isDisposed = false;

  final TextEditingController _controller = TextEditingController();

  final String _key = 'my32lengthsupersecretnooneknows1'; // 32 байта
  List<String> messages = [];
  List<String> sender = [];
  List<String> created = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    print('initState вызван');

    // Инициализируем данные
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('Инициализация приложения...');

    try {
      // Получаем deviceId
      await _getDeviceId();

      // Загружаем сообщения
      await _fetchMessages();
    } catch (e) {
      print('Ошибка инициализации: $e');
      _safeSetState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка загрузки: $e';
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        print('Android Device ID: $deviceId');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown-ios';
        print('iOS Device ID: $deviceId');
      } else {
        deviceId = 'unknown-platform';
      }
    } catch (e) {
      print('Error getting device ID: $e');
      deviceId = 'test-device-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    print('Отправка сообщения: $message');

    // Добавляем сообщение локально
    final String senderIn = 'Вы';
    final String createdAt = DateTime.now().toString().substring(0, 19);

    _safeSetState(() {
      sender.add(senderIn);
      messages.add(message);
      created.add(createdAt);
    });

    _scrollToBottom();

    // Отправляем на сервер
    try {
      final iv = encrypt.IV.fromLength(16);
      final encrypter =
          encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(_key)));
      final encrypted = encrypter.encrypt(message, iv: iv);

      final response = await http.post(
        Uri.parse('https://anchih.e-rec.ru/api/store_message.php'),
        body: json.encode({
          'message': encrypted.base64,
          'iv': iv.base64,
          'sender': deviceId,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      print('Статус отправки: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Тело ответа: ${response.body}');
      }
    } catch (e) {
      print('Ошибка отправки: $e');
    }
  }

  Future<void> _fetchMessages() async {
    print('Загрузка сообщений...');

    _safeSetState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://anchih.e-rec.ru/api/get_messages.php'),
        headers: {'Accept': 'application/json'},
      );

      print('Статус загрузки: ${response.statusCode}');

      if (!mounted || _isDisposed) return;

      if (response.statusCode == 200) {
        final List<dynamic> jsonMessages;

        try {
          jsonMessages = json.decode(response.body);
          print('Получено ${jsonMessages.length} сообщений с сервера');
        } catch (e) {
          print('Ошибка парсинга JSON: $e');
          _safeSetState(() {
            _isLoading = false;
            _errorMessage = 'Ошибка формата данных';
          });
          return;
        }

        // Если нет сообщений
        if (jsonMessages.isEmpty) {
          print('Сервер вернул пустой массив сообщений');
          _safeSetState(() {
            _isLoading = false;
          });
          return;
        }

        List<String> tempMessages = [];
        List<String> tempSender = [];
        List<String> tempCreated = [];
        int validCount = 0;

        for (var jsonMessage in jsonMessages) {
          try {
            // Проверка типа
            if (jsonMessage is! Map<String, dynamic>) {
              print('Некорректный формат, пропускаем');
              continue;
            }

            // Выводим полную структуру для отладки
            print('Сообщение с сервера: $jsonMessage');

            // Получаем данные
            final dynamic ivBase64 = jsonMessage['iv'];
            final dynamic encryptedMessage = jsonMessage['message'];
            final dynamic senderIn = jsonMessage['sender'];
            final dynamic createdAt = jsonMessage['created_at'];

            // Проверка на пустые значения
            if (ivBase64 == null ||
                encryptedMessage == null ||
                ivBase64.toString().trim().isEmpty ||
                encryptedMessage.toString().trim().isEmpty) {
              print('Пустые данные, пропускаем');
              continue;
            }

            // Дешифрование
            final iv = encrypt.IV.fromBase64(ivBase64.toString());
            final encrypter =
                encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(_key)));
            final decrypted =
                encrypter.decrypt64(encryptedMessage.toString(), iv: iv);

            // Определяем отправителя
            final displaySender = (senderIn?.toString() == deviceId)
                ? "Вы"
                : (senderIn?.toString() ?? "Неизвестный");

            tempSender.add(displaySender);
            tempMessages.add(decrypted);
            tempCreated.add(createdAt?.toString() ?? "Без даты");
            validCount++;

            print(
                'Успешно дешифровано сообщение от $displaySender: $decrypted');
          } catch (e) {
            print('Ошибка обработки сообщения: $e');
            continue;
          }
        }

        if (!mounted || _isDisposed) return;

        _safeSetState(() {
          _isLoading = false;
          messages = tempMessages;
          sender = tempSender;
          created = tempCreated;
        });

        print('Итог: валидных $validCount из ${jsonMessages.length}');

        // Прокрутка
        if (validCount > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      } else {
        print('Ошибка HTTP: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        _safeSetState(() {
          _isLoading = false;
          _errorMessage = 'Ошибка сервера: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Ошибка сети: $e');
      _safeSetState(() {
        _isLoading = false;
        _errorMessage = 'Нет подключения к интернету';
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && messages.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Widget _buildMessageList() {
    print(
        '_buildMessageList: isLoading=$_isLoading, messages=${messages.length}, error=$_errorMessage');

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка сообщений...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 10),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchMessages,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет сообщений',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Напишите первое сообщение!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(
              sender[index],
              style: TextStyle(
                fontSize: 12,
                color: sender[index] == "Вы" ? Colors.green : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  messages[index],
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    created[index],
                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('build вызван');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сообщения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMessages,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchMessages,
              child: _buildMessageList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        _sendMessage(text.trim());
                        _controller.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) {
                        _sendMessage(text);
                        _controller.clear();
                      }
                    },
                  ),
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
    print('dispose вызван');
    _isDisposed = true;
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
