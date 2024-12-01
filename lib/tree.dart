import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Add this line at the top of your file
import 'package:device_info_plus/device_info_plus.dart';

String arrayObjsT = '{"table": []}';
var tableObjsJson = jsonDecode(arrayObjsT)['table'] as List;
var tableTemp = jsonDecode(arrayObjsT)['table'] as List;
var obj_person = jsonDecode(arrayObjsT)['table'] as List;
var obj_femaly = jsonDecode(arrayObjsT)['table'] as List;

var obj_perents = jsonDecode(arrayObjsT)['table'] as List;
var obj_brothers = jsonDecode(arrayObjsT)['table'] as List;
var obj_children = jsonDecode(arrayObjsT)['table'] as List;
var serche = '1';

class TreeScreenWidget extends StatefulWidget {
  const TreeScreenWidget({super.key});

  @override
  _TreeScreenWidgetState createState() => _TreeScreenWidgetState();
}

class _TreeScreenWidgetState extends State<TreeScreenWidget> {
  final _search = TextEditingController();

  late _ListBuilderState listBuilderState; // Ссылка на состояние ListBuilder

  void onQueryChanged(String query) {
    // Обновляем текст поиска
    _search.text = query;
    serche = query;

    // Очищаем временный список
    tableTemp.clear();

    // Проверяем, если строка поиска не пустая
    if (query.isNotEmpty) {
      for (int i = 0; i < tableObjsJson.length; i++) {
        String myString = tableObjsJson[i]["name"];
        if (myString.contains(query)) {
          tableTemp.add({
            "n_id": tableObjsJson[i]["n_id"],
            "name": tableObjsJson[i]["name"],
            "age": tableObjsJson[i]["age"],
            "birthday": tableObjsJson[i]["birthday"]
          });
        }
      }
    }

    // Отладочный вывод
    print(tableTemp);

// Обновляем состояние ListBuilder
    listBuilderState.change(); // Вызываем метод change() у ListBuilderState
  }

  String deviceId = 'unknown';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Древо')),
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListBuilderState(
                onChange: (state) {
                  listBuilderState = state; // Сохраняем состояние ListBuilder
                },
              ),
            ),
            TextField(
              controller: _search,
              onChanged: onQueryChanged,
              cursorColor: Colors.grey,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                hintText: 'Поиск..',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(15),
                  width: 12,
                  height: 5,
                  child: Icon(Icons.search),
                ),
              ),
            ),
          ],
        ));
  }
}

class ListBuilderState extends StatefulWidget {
  // const ListBuilderState({super.key});
  const ListBuilderState({super.key, required this.onChange});
  final Function(_ListBuilderState) onChange; // Параметр обратного вызова

  @override
  State<ListBuilderState> createState() => _ListBuilderState();
}

class _ListBuilderState extends State<ListBuilderState> {
  Future<String> download() async {
    print("Future");
    if (tableTemp.length >= 1 || serche.length > 1) {
      print("tableTemp");
      return Future.value("Data download"); // return your response
    } else {
      var request =
          await HttpClient().getUrl(Uri.parse('https://anchih.e-rec.ru/api/'));
      // sends the request
      var response = await request.close();
      // transforms and prints the response
      await for (var contents in response.transform(const Utf8Decoder())) {
        tableObjsJson = jsonDecode(contents)['table'] as List;
        tableTemp = jsonDecode(contents)['table'] as List;
      }
      return Future.value("Data download"); // return your response
    }
  }

  void change() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.onChange(this); // Передаем текущее состояние родительскому виджету
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: download(), // function where you call your api
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          // AsyncSnapshot<Your object type>
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text('Идет загрузка...'));
          } else {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return Center(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: tableTemp.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.man),
                        title: Text(tableTemp[index]["name"]),
                        // ignore: prefer_interpolation_to_compose_strings
                        subtitle: Text(
                          "${"Возрасть:" + tableTemp[index]["age"]} год.рождения:" +
                              tableTemp[index]["birthday"],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.family_restroom),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return GenealogyTree(
                                          tableTemp[index]["name"],
                                          tableTemp[index]["n_id"]);
                                    });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.account_circle),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return add_person(
                                          tableTemp[index]["name"],
                                          tableTemp[index]["n_id"]);
                                    });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.info),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return _alert_list(
                                          tableTemp[index]["n_id"]);
                                    });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          }
        });
  }
}

class _alert_list extends StatelessWidget {
  String id_person;
  _alert_list(this.id_person);

  Future<String> get_person() async {
    var request = await HttpClient()
        .getUrl(Uri.parse('https://anchih.e-rec.ru/api/person?id=$id_person'));
    // sends the request
    var response = await request.close();
    // transforms and prints the response
    await for (var contents in response.transform(const Utf8Decoder())) {
      obj_person = jsonDecode(contents)['person'] as List;
    }
    return Future.value("Data download"); // return your response
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: get_person(), // function where you call your api
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          // AsyncSnapshot<Your object type>
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text('Идет загрузка...'));
          } else {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return AlertDialog(
                title: Center(
                  child: Column(
                    children: [
                      Text(obj_person[0]["name"]),
                      //for (final word in obj_person)
                      for (var i = 1; i <= obj_person.length - 1; i++)
                        Card(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(obj_person[i]["kinship"]),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(obj_person[i]["name"]),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  InkWell(
                                    child: const Icon(Icons.info),
                                    onTap: () {
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return _alert_list(
                                                obj_person[i]["n_id"]);
                                          });
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                obj_person[i]["birthday"],
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }
          }
        });
  }
}

class add_person extends StatefulWidget {
  String id_person;
  String id_name;
  add_person(this.id_name, this.id_person);

  @override
  _add_person createState() => _add_person(id_name, id_person);
}

class _add_person extends State<add_person> {
  String id_person;
  String id_name;
  _add_person(this.id_name, this.id_person);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController relationController = TextEditingController();

  final TextEditingController _ageController = TextEditingController();
  DateTime? _selectedDate;

  String? selectedFams; // Для хранения выбранного значения

  List<List<String>> fams = [];

  String? selectedRelation; // Для хранения выбранного значения
  List<String> relations = [
    'Сын',
    'Дочь',
  ];

  Future<String> getFamaly() async {
    var request = await HttpClient().getUrl(Uri.parse(
        'https://anchih.e-rec.ru/api/person/getfamaly.php?id=$id_person'));
    // sends the request
    var response = await request.close();
    // transforms and prints the response
    await for (var contents in response.transform(const Utf8Decoder())) {
      obj_femaly = jsonDecode(contents)['person'] as List;
      // Преобразуем данные в список строк
      fams = obj_femaly
          .map((item) => [item['name'].toString(), item['FAMC'].toString()])
          .toList();
    }
    return Future.value("Data download"); // return your response
  }

  Future<void> _sendDataToServer(String id_famaly, String name, String surname,
      String age, String relation) async {
    final url = Uri.parse(
        'https://anchih.e-rec.ru/api/person/add_person.php'); // Замените на ваш URL

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'id_person': id_person,
        'person_name': id_name,
        'id_famaly': id_famaly,
        //'famaly_name': famaly_name,
        'name': name,
        'surname': surname,
        'age': age,
        'relation': relation,
      }),
    );

    if (response.statusCode == 200) {
      // Успешно отправлено
      print('Данные успешно отправлены');
      // Закрываем форму
      try {
        final responseJson = jsonDecode(response.body);
        if (responseJson['answer'] == 'ok') {
          Navigator.of(context).pop();
        } else {
          print('Ошибка при отправке данных: ${responseJson}');
          _showErrorDialog(responseJson['answer']);
        }
      } catch (e) {
        print('Ошибка декодирования JSON: $e');
        _showErrorDialog('Ошибка декодирования JSON: $e');
      }
    } else {
      // Ошибка при отправке
      print('Ошибка при отправке данных: ${response.statusCode}');
      // Показываем сообщение об ошибке
      _showErrorDialog('Ошибка при отправке данных: ${response.statusCode}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ответ сервера'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Закрыть диалог
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
        _ageController.text = DateFormat('d MMMM yyyy').format(_selectedDate!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: getFamaly(), // function where you call your api
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          // AsyncSnapshot<Your object type>
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text('Идет загрузка...'));
          } else {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return AlertDialog(
                title: Column(
                  children: [
                    Text(id_name),
                    Text(
                      'Добавление детей',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedFams,
                        decoration: InputDecoration(labelText: 'к супругу(е)'),
                        items: fams.map((List<String> fam) {
                          return DropdownMenuItem<String>(
                            value: fam[1],
                            child: Text(fam[0]),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          selectedFams = newValue;
                        },
                      ),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'Имя'),
                      ),
                      TextField(
                        controller: surnameController,
                        decoration: InputDecoration(labelText: 'Фамилия'),
                      ),
                      TextField(
                        controller: _ageController,
                        decoration: InputDecoration(labelText: 'Год рождения'),
                        keyboardType: TextInputType.number,
                        readOnly: true,
                        onTap: _presentDatePicker,
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedRelation,
                        decoration: InputDecoration(labelText: 'Отношение'),
                        items: relations.map((String relation) {
                          return DropdownMenuItem<String>(
                            value: relation,
                            child: Text(relation),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          selectedRelation = newValue;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (selectedFams == null) {
                        _showErrorDialog(
                            'Пожалуйста, выберите мать для ребенка');
                        return;
                      }
                      // Проверка на заполненность полей
                      if (nameController.text.isEmpty) {
                        // Здесь можно показать сообщение об ошибке
                        _showErrorDialog('Пожалуйста, введите имя');
                        return;
                      }
                      if (surnameController.text.isEmpty) {
                        _showErrorDialog('Пожалуйста, введите фамилию');
                        return;
                      }
                      if (_ageController.text.isEmpty) {
                        _showErrorDialog('Пожалуйста, выберите год рождения');
                        return;
                      }
                      if (selectedRelation == null) {
                        _showErrorDialog('Пожалуйста, выберите отношение');
                        return;
                      }

                      // Если все проверки пройдены, отправляем данные на сервер
                      _sendDataToServer(
                        selectedFams!,
                        nameController.text,
                        surnameController.text,
                        _ageController.text,
                        selectedRelation!,
                      );

                      // Закрыть диалог после успешной отправки
                      // Navigator.of(context).pop();
                    },
                    child: Text('Отправить'),
                  ),
                ],
              );
            }
          }
        });
  }
}

class GenealogyTree extends StatelessWidget {
  String id_person;
  String id_name;
  GenealogyTree(this.id_name, this.id_person);

  Future<String> get_person() async {
    var request = await HttpClient().getUrl(
        Uri.parse('https://anchih.e-rec.ru/api/person/tree.php?id=$id_person'));
    // sends the request
    var response = await request.close();
    // transforms and prints the response
    await for (var contents in response.transform(const Utf8Decoder())) {
      obj_perents = jsonDecode(contents)['perents'] as List;
      obj_brothers = jsonDecode(contents)['brothers'] as List;
      obj_children = jsonDecode(contents)['children'] as List;
    }
    return Future.value("Data download"); // return your response
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: get_person(), // function where you call your api
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          // AsyncSnapshot<Your object type>
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text('Идет загрузка...'));
          } else {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return AlertDialog(
                title: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Второе поколение: Родители
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i <= obj_perents.length - 1; i++)
                              Row(
                                children: [
                                  PersonNode(
                                    kinship: obj_perents[i]["kinship"],
                                    name: obj_perents[i]["name"],
                                    color: Colors.blueAccent,
                                  ),
                                  SizedBox(width: 10),
                                ],
                              ),

                            //PersonNode(name: 'Мать'),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),

                      // Третье поколение: Вы
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i <= obj_brothers.length - 1; i++)
                              Row(
                                children: [
                                  PersonNode(
                                    kinship: obj_brothers[i]["kinship"],
                                    name: obj_brothers[i]["name"],
                                    color: (obj_brothers[i]["kinship"] == '-')
                                        ? Colors.black
                                        : Colors.blueAccent,
                                  ),
                                  SizedBox(width: 10),
                                ],
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),

                      // Четвертое поколение: Дети
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i <= obj_children.length - 1; i++)
                              Row(
                                children: [
                                  PersonNode(
                                    kinship: obj_children[i]["kinship"],
                                    name: obj_children[i]["name"],
                                    color: Colors.blueAccent,
                                  ),
                                  SizedBox(width: 10),
                                ],
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            }
          }
        });
  }
}

class PersonNode extends StatelessWidget {
  final String kinship;
  final String name;
  //final Color color=Colors.blueAccent;
  final Color color;
  const PersonNode(
      {required this.kinship, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                kinship,
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
              Text(
                name,
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
