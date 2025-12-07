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
      var request = await HttpClient().getUrl(
          Uri.parse('https://anchih.e-rec.ru/api/feed/get_feed.php'));
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
  bool _isInitialized = false;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    
    // Проверяем, является ли URL видео
    final url = widget.item['url_feed'].toString().toLowerCase();
    _isVideo = url.endsWith('.mp4') || 
               url.contains('.mp4?') || 
               url.endsWith('.mov') ||
               url.endsWith('.avi') ||
               url.endsWith('.wmv') ||
               url.endsWith('.flv') ||
               url.endsWith('.webm');
    
    // Создаем контроллер только для видео файлов
    if (_isVideo) {
      _videoPlayerController = VlcPlayerController.network(
        '', // Начинаем с пустого URL
        autoPlay: false,
      );
    }
  }

  void _initializeVideo() async {
    if (!_isVideo || _videoPlayerController == null || _isInitialized) return;
    
    try {
      // Устанавливаем медиа из сети
      await _videoPlayerController!.setMediaFromNetwork(widget.item['url_feed']);
      
      setState(() {
        _isInitialized = true;
      });
      
      // Начинаем воспроизведение
      await _videoPlayerController!.play();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print("Ошибка инициализации видео: $e");
    }
  }

  void _togglePlay() async {
    if (!_isVideo || _videoPlayerController == null) return;
    
    if (!_isInitialized) {
      await _initializeVideo();
      return;
    }
    
    if (_isPlaying) {
      await _videoPlayerController!.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _videoPlayerController!.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _stopVideo() async {
    if (!_isVideo || _videoPlayerController == null || !_isInitialized) return;
    
    try {
      await _videoPlayerController!.stop();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      print("Ошибка остановки видео: $e");
    }
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      _stopVideo();
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
          if (_isVideo)
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                height: widget.height_n / 3,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Видео плеер
                    if (_isInitialized && _videoPlayerController != null)
                      VlcPlayer(
                        controller: _videoPlayerController!,
                        aspectRatio: 16 / 9,
                        placeholder: Container(
                          color: Colors.black,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    
                    // Превью или иконка play
                    if (!_isInitialized || !_isPlaying)
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: Icon(
                            _isInitialized && !_isPlaying ? Icons.play_arrow : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    
                    // Индикатор воспроизведения
                    if (_isPlaying && _isInitialized)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.pause,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            // Для изображений
            Container(
              height: widget.height_n / 3,
              width: double.infinity,
              child: Image.network(
                widget.item['url_feed'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
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
