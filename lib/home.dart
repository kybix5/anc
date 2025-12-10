import 'package:flutter/material.dart';

class HomeScreenWidget extends StatefulWidget {
  final Function(int) onTabChanged;
  const HomeScreenWidget({super.key, required this.onTabChanged});

  @override
  _HomeScreenWidgetState createState() =>
      _HomeScreenWidgetState(onTabChanged: onTabChanged);
}

class _HomeScreenWidgetState extends State<HomeScreenWidget> {
  final Function(int) onTabChanged;
  _HomeScreenWidgetState({required this.onTabChanged});
  var size, height, width;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;

    return Center(
        child: Stack(fit: StackFit.expand, children: <Widget>[
      Image(
        image: const AssetImage('assets/images/gory.jpg'),
        width: width,
        height: height,
        fit: BoxFit.fill,
      ),
      Column(
        //mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            child: SizedBox(
              width: width / 15,
              height: height / 40,
            ),
          ),
          Container(
            child: Row(
              children: [
                SizedBox(
                  child: SizedBox(
                    width: width / 15,
                    height: height / 20,
                  ),
                ),
                Container(
                  //width: width / 2.5,
                  //height: height / 3,
                  child: Material(
                    color: Colors.purple,
                    elevation: 100,
                    shadowColor: Colors.blue,
                    borderRadius: BorderRadius.circular(28),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Stack(
                      alignment: Alignment.bottomCenter, //Here
                      children: [
                        InkWell(
                          onTap: () {
                            onTabChanged(1);
                          },
                          child: Column(
                            children: [
                              Ink.image(
                                image: const NetworkImage(
                                  'https://anchih.e-rec.ru/api/jpg/camera.jpg',
                                ),
                                height: height / 4,
                                width: width / 2.5,
                                fit: BoxFit.fill,
                              ),
                              const Text(
                                'Камера',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  child: SizedBox(
                    width: width / 15,
                    height: height / 20,
                  ),
                ),
                Container(
                  //width: width / 2.5,
                  //height: height / 3,
                  child: Material(
                    color: Colors.purple,
                    elevation: 100,
                    shadowColor: Colors.blue,
                    borderRadius: BorderRadius.circular(28),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Stack(
                      alignment: Alignment.bottomCenter, //Here
                      children: [
                        InkWell(
                          onTap: () {
                            onTabChanged(2);
                          },
                          child: Column(
                            children: [
                              Ink.image(
                                image: const NetworkImage(
                                  'https://anchih.e-rec.ru/api/jpg/tree.jpg',
                                ),
                                height: height / 4,
                                width: width / 2.5,
                                fit: BoxFit.fill,
                              ),
                              const Text(
                                'Древо',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            child: SizedBox(
              width: width / 15,
              height: height / 40,
            ),
          ),
          Container(
            child: Row(
              children: [
                SizedBox(
                  child: SizedBox(
                    width: width / 15,
                    height: height / 20,
                  ),
                ),
                Container(
                  //width: width / 2.5,
                  //height: height / 3,
                  child: Material(
                    color: Colors.purple,
                    elevation: 100,
                    shadowColor: Colors.blue,
                    borderRadius: BorderRadius.circular(28),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Stack(
                      alignment: Alignment.bottomCenter, //Here
                      children: [
                        InkWell(
                          onTap: () {
                            onTabChanged(3);
                          },
                          child: Column(
                            children: [
                              Ink.image(
                                image: const NetworkImage(
                                  'https://anchih.e-rec.ru/api/jpg/news.jpeg',
                                ),
                                height: height / 4,
                                width: width / 2.5,
                                fit: BoxFit.fill,
                              ),
                              const Text(
                                'Новости',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  child: SizedBox(
                    width: width / 15,
                    height: height / 20,
                  ),
                ),
                Container(
                  //width: width / 2.5,
                  //height: height / 3,
                  child: Material(
                    color: Colors.purple,
                    elevation: 100,
                    shadowColor: Colors.blue,
                    borderRadius: BorderRadius.circular(28),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Stack(
                      alignment: Alignment.bottomCenter, //Here
                      children: [
                        InkWell(
                          onTap: () {
                            onTabChanged(5);
                          },
                          child: Column(
                            children: [
                              Ink.image(
                                image: const NetworkImage(
                                  'https://anchih.e-rec.ru/api/jpg/wh.png',
                                ),
                                height: height / 4,
                                width: width / 2.5,
                                fit: BoxFit.fill,
                              ),
                              const Text(
                                'Погода',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ]));
  }
}

class MessageScreenWidget extends StatelessWidget {
  const MessageScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Сообщения',
          style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
    );
  }
}
