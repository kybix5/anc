import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:io';
import 'dart:convert';

class FeedScreenWidget extends StatefulWidget {
  @override
  _FeedScreenWidgetState createState() => _FeedScreenWidgetState();
}

class _FeedScreenWidgetState extends State<FeedScreenWidget> {
  static String arrayObjsT = '{"news": []}';
  var size_n, height_n, width_n;

  var tableObjsJson = jsonDecode(arrayObjsT)['news'] as List;

  Future<String> download() async {
    var getdata = false;
    var request = await HttpClient()
        .getUrl(Uri.parse('https://anchih.e-rec.ru/api/news'));
    // sends the request
    var response = await request.close();
    // transforms and prints the response
    await for (var contents in response.transform(Utf8Decoder())) {
      tableObjsJson = jsonDecode(contents)['news'] as List;
      var getdata = true;
    }
    return Future.value("Data download"); // return your response
  }

  @override
  Widget build(BuildContext context) {
    size_n = MediaQuery.of(context).size;
    height_n = size_n.height;
    width_n = size_n.width;

    return FutureBuilder<String>(
      future: download(), // function where you call your api
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        // AsyncSnapshot<Your object type>
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Text('Идет загрузка...'));
        } else {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          else {
            return Scaffold(
                appBar: AppBar(title: Text('Feed')),
                body: Center(
                  child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: tableObjsJson.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          child: ListTile(
                            //leading: CircleAvatar(child: Text('C')),
                            title: Text(
                              tableObjsJson[index]["topic_news"] as String,
                              style: const TextStyle(
                                  fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              tableObjsJson[index]["short_news"] as String,
                              style: const TextStyle(fontSize: 8),
                            ),
                            //trailing: Icon(Icons.favorite_rounded),
                            //isThreeLine: true,
                            onTap: () {
                              if (tableObjsJson[index]["jpg"] != null &&
                                  tableObjsJson[index]["jpg"].isNotEmpty) {
                                AlertDialog alert = AlertDialog(
                                  title: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: height_n /
                                            4, // Задаем фиксированную высоту
                                        child: CarouselSlider(
                                          items: [
                                            for (var i = 0;
                                                i <
                                                    tableObjsJson[index]["jpg"]
                                                        .length;
                                                i++)
                                              Container(
                                                margin: EdgeInsets.all(8.0),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                        tableObjsJson[index]
                                                            ["jpg"][i]),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                          ],
                                          options: CarouselOptions(
                                            enlargeCenterPage: true,
                                            autoPlay: true,
                                            aspectRatio: 16 / 9,
                                            autoPlayCurve: Curves.fastOutSlowIn,
                                            enableInfiniteScroll: true,
                                            autoPlayAnimationDuration:
                                                Duration(milliseconds: 800),
                                            viewportFraction: 0.8,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: height_n / 4,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              Text(
                                                tableObjsJson[index]
                                                        ["full_news"] ??
                                                    "Нет данных",
                                                style: const TextStyle(
                                                    fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return alert;
                                  },
                                );
                              } else {
                                print("Нет изображений для отображения");
                              }
                            },
                          ),
                        );
                      }),
                ));
          }
        }
      },
    );
  }
}
