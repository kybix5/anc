import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:io';
import 'dart:convert';

class FeedScreenWidget extends StatefulWidget {
  @override
  _FeedScreenWidgetState createState() => _FeedScreenWidgetState();
}

class _FeedScreenWidgetState extends State<FeedScreenWidget> {
  var size_n, height_n, width_n;
  List tableObjsJson = [];

  Future<String> download() async {
    try {
      var request = await HttpClient()
          .getUrl(Uri.parse('https://anchih.e-rec.ru/api/feed/get_feed.php'));
      var response = await request.close();

      await for (var contents in response.transform(Utf8Decoder())) {
        tableObjsJson = jsonDecode(contents) as List;
      }
    } catch (e) {
      print("Ошибка загрузки: $e");
    }

    return Future.value("Data download");
  }

  @override
  Widget build(BuildContext context) {
    size_n = MediaQuery.of(context).size;
    height_n = size_n.height;
    width_n = size_n.width;

    return FutureBuilder<String>(
      future: download(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Text('Идет загрузка...'));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Scaffold(
            appBar: AppBar(title: Text('Лента')),
            body: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: tableObjsJson.length,
              itemBuilder: (BuildContext context, int index) {
                var item = tableObjsJson[index];
                return FeedCard(item: item, height_n: height_n);
              },
            ),
          );
        }
      },
    );
  }
}

class FeedCard extends StatefulWidget {
  final Map item;
  final double height_n;
  FeedCard({required this.item, required this.height_n});

  @override
  _FeedCardState createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  VlcPlayerController? _videoPlayerController;
  bool _isPlaying = false;
  bool _isVideo = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Определяем, является ли URL видео
    final url = widget.item['url_feed'].toString().toLowerCase();
    _isVideo = url.endsWith('.mp4') ||
        url.contains('.mp4?') ||
        url.endsWith('.mov') ||
        url.endsWith('.avi') ||
        url.endsWith('.wmv') ||
        url.endsWith('.flv') ||
        url.endsWith('.webm');
  }

  Future<void> _togglePlay() async {
    if (!_isVideo) return;

    if (_videoPlayerController == null) {
      setState(() => _isLoading = true);

      try {
        // Создаем контроллер с URL при первом нажатии
        _videoPlayerController = VlcPlayerController.network(
          widget.item['url_feed'],
          //hwAcc: HwAcc.FULL,
          autoPlay: true,
          options: VlcPlayerOptions(),
        );

        setState(() {
          _isPlaying = true;
          _isLoading = false;
        });
      } catch (e) {
        print("Ошибка инициализации видео: $e");
        setState(() => _isLoading = false);
      }
    } else {
      try {
        if (_isPlaying) {
          await _videoPlayerController!.pause();
        } else {
          await _videoPlayerController!.play();
        }
        setState(() => _isPlaying = !_isPlaying);
      } catch (e) {
        print("Ошибка переключения воспроизведения: $e");
      }
    }
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      try {
        if (_videoPlayerController!.value.isInitialized) {
          _videoPlayerController!.stop();
        }
      } catch (e) {
        print("Ошибка при stop(): $e");
      }
      _videoPlayerController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isVideo
              ? GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    height: widget.height_n / 3,
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Видео плеер
                        if (_videoPlayerController != null)
                          VlcPlayer(
                            controller: _videoPlayerController!,
                            aspectRatio: 16 / 9,
                            placeholder: Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),

                        // Индикатор загрузки
                        if (_isLoading)
                          Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),

                        // Иконка Play
                        if (!_isPlaying && !_isLoading)
                          Icon(
                            Icons.play_circle_filled,
                            size: 50,
                            color: Colors.white,
                          ),

                        // Иконка Pause
                        if (_isPlaying)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Icon(
                              Icons.pause,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : Container(
                  height: widget.height_n / 3,
                  width: double.infinity,
                  child: Image.network(
                    widget.item['url_feed'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              widget.item['description'] ?? '',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
