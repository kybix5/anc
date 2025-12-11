import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
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

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _getDeviceId();
    await _fetchProfileData();
    setState(() => isLoading = false);
  }

  // ---------- Получение deviceId ----------
  Future<void> _getDeviceId() async {
    DeviceInfoPlugin info = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo android = await info.androidInfo;
      deviceId = android.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo ios = await info.iosInfo;
      deviceId = ios.identifierForVendor ?? "unknown";
    }
  }

  // ---------- Загрузка профиля через API ----------
  Future<void> _fetchProfileData() async {
    if (deviceId == "unknown") {
      _setTestData();
      return;
    }

    try {
      final encodedId = Uri.encodeComponent(deviceId.trim());
      final url = 'https://anchih.e-rec.ru/api/profile/?id=$encodedId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Проверка формата
        if (data is Map<String, dynamic>) {
          _applyProfileFromApi(data);
          return;
        }
      }

      // Если сервер вернул что-то странное → тестовые данные
      _setTestData();

    } catch (e) {
      print("Ошибка API: $e");
      _setTestData();
    }
  }

  // ---------- Установка данных из API ----------
  void _applyProfileFromApi(Map<String, dynamic> data) {
    firstNameController.text = data['first_name'] ?? "";
    lastNameController.text = data['last_name'] ?? "";
    emailController.text = data['email'] ?? "";
    usernameController.text = data['username'] ?? "";
    _imageUrl = data['photo'];
  }

  // ---------- Тестовые данные при ошибке ----------
  void _setTestData() {
    firstNameController.text = "Иван";
    lastNameController.text = "Иванов";
    emailController.text = "test@example.com";
    usernameController.text = "testuser";
    _imageUrl = null;
  }

  // ---------- Отправка формы ----------
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
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ошибка сервера")));
      }
    } catch (e) {
      print("Ошибка отправки: $e");
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Настройки профиля")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Настройки профиля")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
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
              SizedBox(height: 20),

              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: "Имя"),
              ),

              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: "Фамилия"),
              ),

              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
              ),

              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(labelText: "Имя пользователя"),
              ),

              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Сохранить"),
                onPressed: _submitSettings,
              )
            ],
          ),
        ),
      ),
    );
  }
}
