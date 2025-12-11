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

  bool isLoading = true; // ← важно!

  @override
  void initState() {
    super.initState();
    _initProfile();   // ← единственная точка входа
  }

  Future<void> _initProfile() async {
    await getDeviceId();
    await _loadLocalCache();
    await _fetchProfileData();
    setState(() => isLoading = false);
  }

  // ---------- Получение deviceId ----------
  Future<void> getDeviceId() async {
    DeviceInfoPlugin info = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo android = await info.androidInfo;
      deviceId = android.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo ios = await info.iosInfo;
      deviceId = ios.identifierForVendor ?? "unknown";
    }
  }

  // ---------- Локальный кэш ----------
  Future<void> _loadLocalCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    firstNameController.text = prefs.getString("first_name") ?? "";
    lastNameController.text = prefs.getString("last_name") ?? "";
    emailController.text = prefs.getString("email") ?? "";
    usernameController.text = prefs.getString("username") ?? "";
    _imageUrl = prefs.getString("photo");
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

  // ---------- Загрузка профиля с API ----------
  Future<void> _fetchProfileData() async {
    if (deviceId == "unknown") return;

    try {
      final encodedId = Uri.encodeComponent(deviceId.trim());
      final url = 'https://anchih.e-rec.ru/api/profile/?id=$encodedId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          firstNameController.text = data['first_name'] ?? "";
          lastNameController.text = data['last_name'] ?? "";
          emailController.text = data['email'] ?? "";
          usernameController.text = data['username'] ?? "";
          _imageUrl = data['photo'];

          await _saveLocalCache(data);
        }
      }
    } catch (e) {
      print("Ошибка запроса: $e");
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
                onPressed: () {},
              )
            ],
          ),
        ),
      ),
    );
  }
}
