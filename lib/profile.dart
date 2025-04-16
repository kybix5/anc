import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class ProfileSettings extends StatefulWidget {
  @override
  _ProfileSettingsState createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _email = '';
  String _firstName = '';
  String _lastName = '';

  String deviceId = 'unknown';

  String? _imageUrl =
      'https://anchih.e-rec.ru/api/jpg/photo.jpeg'; // Переменная для хранения URL изображения
  File? _image; // Переменная для хранения локального изображения

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getDeviceId();
    _fetchProfileData(); // Вызов функции для получения данных профиля при открытии экрана
  }

  @override
  void initState() {
    super.initState();
    // getDeviceId();
    //_fetchProfileData(); // Вызов функции для получения данных профиля при открытии экрана
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://anchih.e-rec.ru/api/profile/get_profile&id=$deviceId')); // Замените на ваш URL
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _username = data['username'];
          _email = data['email'];
          _firstName = data['first_name'];
          _lastName = data['last_name'];
          _imageUrl = data[
              'photo']; // Предполагается, что URL изображения возвращается в ответе
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка получения данных профиля')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    //final picker = ImagePicker();
    //final pickedFile = await picker.getImage(source: ImageSource.gallery);
/*
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
*/
  }

  Future<void> _submitSettings() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Подготовка данных для отправки
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://anchih.e-rec.ru/api/profile/update_profile'), // Замените на ваш URL
      );

      // Добавление полей формы
      request.fields['username'] = _username;
      request.fields['email'] = _email;
      request.fields['first_name'] = _firstName;
      request.fields['last_name'] = _lastName;

      // Добавление изображения, если оно выбрано
      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _image!.path),
        );
      }

      // Отправка запроса
      final response = await request.send();

      if (response.statusCode == 200) {
        // Обработка успешного ответа
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Настройки обновлены')),
        );
      } else {
        // Обработка ошибки
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления настроек')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Настройки профиля')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 100,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : _imageUrl != null
                          ? NetworkImage(_imageUrl!)
                          : null,
                  child: _image == null && _imageUrl == null
                      ? Icon(Icons.camera_alt, size: 50)
                      : null,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Имя'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите имя';
                  }
                  return null;
                },
                onSaved: (value) {
                  _firstName = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Фамилия'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите фамилию';
                  }
                  return null;
                },
                onSaved: (value) {
                  _lastName = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+.[^@]+').hasMatch(value)) {
                    return 'Пожалуйста, введите корректный email';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Имя пользователя'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите имя пользователя';
                  }
                  return null;
                },
                onSaved: (value) {
                  _username = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitSettings,
                child: Text('Сохранить изменения'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
