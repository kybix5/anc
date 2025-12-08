import 'package:flutter/material.dart';

import 'home.dart';
import 'tree.dart';
import 'vlc.dart';
import 'news.dart';
import 'feed.dart';
import 'weather.dart';
import 'massege.dart';
import 'profile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Анчих1',
      home: BottomNavExample(),
    );
  }
}

class BottomNavExample extends StatefulWidget {
  const BottomNavExample({super.key});

  @override
  _BottomNavExampleState createState() => _BottomNavExampleState();
}

class _BottomNavExampleState extends State<BottomNavExample> {
  int _currentIndex = 0;
  int _currentNavigator = 0;

  var size, height, width;

  void _onTabChanged(int index) {
    setState(() {
      _currentNavigator = index; // Обновляем индекс выбранной вкладки
      if (index == 7) {
        _currentIndex = 0; // Сбрасываем текущий индекс на 0

        Navigator.pop(context); // Закрыть Drawer
      } else {
        _currentIndex = index; // Устанавливаем текущий индекс на выбранный
      }
    });
  }

  // Список экранов
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreenWidget(onTabChanged: _onTabChanged),
      CameraScreenWidget(),
      TreeScreenWidget(),
      NewsScreenWidget(),
      FeedScreenWidget(),
      WeatherScreenWidget(),
      MessageWidget(),
      ProfileSettings(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;

    var drawerTextColor = TextStyle(
      color: Colors.grey[600],
    );
    var tilePadding = const EdgeInsets.only(left: 8.0, right: 8, top: 8);
    var myDrawer = Drawer(
      backgroundColor: Colors.grey[300],
      elevation: 0,
      child: Column(
        children: [
          const DrawerHeader(
            child: Icon(
              Icons.settings_rounded,
              size: 64,
            ),
          ),
          Padding(
            padding: tilePadding,
            child: ListTile(
              // onTap: naveel_camera,
              leading: const Icon(Icons.home),
              title: Text(
                'L O G I N',
                style: drawerTextColor,
              ),
            ),
          ),
          Padding(
            padding: tilePadding,
            child: ListTile(
              leading: const Icon(Icons.settings),
              onTap: () {
                _onTabChanged(7);
              },
              title: Text(
                'S E T T I N G S',
                style: drawerTextColor,
              ),
            ),
          ),
          Padding(
            padding: tilePadding,
            child: ListTile(
              leading: const Icon(Icons.info),
              title: Text(
                'A B O U T',
                style: drawerTextColor,
              ),
            ),
          ),
          Padding(
            padding: tilePadding,
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: Text(
                'L O G O U T',
                style: drawerTextColor,
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Анчих'),
      ),
      drawer: myDrawer,
      body: _screens[_currentNavigator], // Получаем виджет по индексу
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            backgroundColor: Colors.green,
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            backgroundColor: Colors.green,
            label: 'Камера',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            backgroundColor: Colors.green,
            label: 'Древо',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fiber_new_sharp),
            backgroundColor: Colors.green,
            label: 'Новости',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fiber_new_sharp),
            backgroundColor: Colors.green,
            label: 'feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_queue_outlined),
            backgroundColor: Colors.green,
            label: 'Погода',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.messenger_sharp),
            backgroundColor: Colors.green,
            label: 'смс',
          ),
        ],
        currentIndex: _currentIndex, //какая ячейка будет выделенна
        selectedItemColor: Colors.blue,
        onTap: _onTabChanged,
      ),
    );
  }
}
