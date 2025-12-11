import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ProfileSettings extends StatefulWidget {
  @override
  _ProfileSettingsState createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();

  String deviceId = "unknown";

  String? _imageUrl;
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadLocalCache();        // ← Загружаем локальные данные
    getDeviceId();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getDeviceId();
    _fetchProfileData();
  }

  // ========== Получение deviceId ==========
  Future<void> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo info = await deviceInfo.androidInfo;
      deviceId = info.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo info = await deviceInfo.iosInfo;
      deviceId = info.identifierForVendor ?? "unknown";
    }

    print("Device ID = $deviceId");
  }

  // ========== Локальный кэш ==========
  Future<void> _loadLocalCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Загружаем данные в поля
    firstNameController.text = prefs.getString("first_name") ?? "";
    lastNameController.text = prefs.getString("last_name") ?? "";
    emailController.text = prefs.getString("email") ?? "";
    usernameController.text = prefs.getString("username") ?? "";
    _imageUrl = prefs.getString("photo");

    setState(() {});
  }

  Future<void> _saveLocalCache(Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString("first_name", data['first_name'] ?? "");
    await prefs.setString("last_name", data['last_name'] ?? "");
    await prefs.setString("email", data['email'] ?? "");
    await prefs.setString("username", data['username'] ?? "");
    if (data['photo'] != null) {
      await prefs.setString("photo", data['photo']);
    }
  }

  // ========== Загрузка профиля с API ==========
  Future<void> _fetchProfileData() async {
    if (deviceId == "unknown") return;

    try {
      final encodedId = Uri.encodeComponent(deviceId.trim());
      final url = 'https://anchih.e-rec.ru/api/profile/?id=$encodedId';

      final response = await http.get(Uri.parse(url));

      print("Ответ сервера: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          // Заполняем поля
          firstNameController.text = data['first_name'] ?? "";
          lastNameController.text = data['last_name'] ?? "";
          emailController.text = data['email'] ?? "";
          usernameController.text = data['username'] ?? "";
          _imageUrl = data['photo'];

          // Сохраняем локально
          await _saveLocalCache(data);

          setState(() {});
        }
      }
    } catch (e) {
      print("Ошибка загрузки данных: $e");
    }
  }

  // ========== Выбор изображения ==========
  Future<void> _pickImage() async {
    // TODO: подключить image_picker
  }

  // ========== Отправка изменений ==========
  Future<void> _submitSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://anchih.e-rec.ru/api/profile/update_profile'));

    request.fields['username'] = usernameController.text;
    request.fields['email'] = emailController.text;
    request.fields['first_name'] = firstNameController.text;
    request.fields['last_name'] = lastNameController.text;

    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath("photo", _image!.path));
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Настройки обновлены")));

        // сохраняем в кэш
        _saveLocalCache({
          "username": usernameController.text,
          "email": emailController.text,
          "first_name": firstNameController.text,
          "last_name": lastNameController.text,
          "photo": _imageUrl
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ошибка сервера")));
      }
    } catch (e) {
      print("Ошибка: $e");
    }
  }

  // ========== UI ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Настройки профиля")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : _imageUrl != null
                          ? NetworkImage(_imageUrl!)
                          : null,
                  child: (_image == null && _imageUrl == null)
                      ? Icon(Icons.camera_alt, size: 50)
                      : null,
                ),
              ),
              SizedBox(height: 20),

              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: "Имя"),
                validator: (v) => v!.isEmpty ? "Введите имя" : null,
              ),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: "Фамилия"),
                validator: (v) => v!.isEmpty ? "Введите фамилию" : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (v) => v!.isEmpty ? "Введите email" : null,
              ),
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(labelText: "Имя пользователя"),
                validator: (v) => v!.isEmpty ? "Введите имя пользователя" : null,
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitSettings,
                child: Text("Сохранить изменения"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
