import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

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
  late VlcPlayerController? _vlcController;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isDisposed = false;

  bool get isVideo {
    final url = widget.item['url_feed'].toString().toLowerCase();
    return url.endsWith('.mp4') || 
           url.contains('.mp4?') || 
           url.contains('.mov') ||
           url.contains('.avi') ||
           url.contains('.wmv') ||
           url.contains('.flv') ||
           url.contains('.webm') ||
           url.contains('/video/');
  }

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    
    // Инициализируем контроллер только для видео, но не запускаем автоматически
    if (isVideo) {
      _initializeController();
    }
  }

  void _initializeController() {
    _vlcController = VlcPlayerController.network(
      widget.item['url_feed'],
      autoPlay: false,
      options: VlcPlayerOptions(),
    );
    
    // Слушаем изменения состояния контроллера
    _vlcController?.addListener(_listener);
  }

  void _listener() {
    if (_isDisposed) return;
    
    if (_vlcController?.value.isInitialized ?? false) {
      if (!_isInitialized) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isLoading = false;
          });
        }
      }
    }
  }

  void _togglePlay() async {
    if (!isVideo || _isDisposed) return;
    
    if (_vlcController == null) {
      _initializeController();
    }
    
    if (!_isInitialized) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _vlcController?.initialize();
        if (mounted && !_isDisposed) {
          setState(() {
            _isInitialized = true;
            _isLoading = false;
            _isPlaying = true;
          });
        }
      } catch (e) {
        print("Ошибка инициализации видео: $e");
        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      try {
        if (_isPlaying) {
          await _vlcController?.pause();
          if (mounted && !_isDisposed) {
            setState(() {
              _isPlaying = false;
            });
          }
        } else {
          await _vlcController?.play();
          if (mounted && !_isDisposed) {
            setState(() {
              _isPlaying = true;
            });
          }
        }
      } catch (e) {
        print("Ошибка переключения воспроизведения: $e");
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // Удаляем слушатель
    _vlcController?.removeListener(_listener);
    
    // Останавливаем воспроизведение
    if (_isPlaying && _vlcController != null) {
      try {
        _vlcController?.pause();
      } catch (e) {
        print("Ошибка при паузе: $e");
      }
    }
    
    // Освобождаем ресурсы
    try {
      _vlcController?.dispose();
    } catch (e) {
      print("Ошибка при dispose: $e");
    }
    
    _vlcController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isVideo)
            GestureDetector(
              onTap: _togglePlay,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: widget.height_n / 3,
                    color: Colors.black,
                    child: (_vlcController != null && _isInitialized)
                        ? VlcPlayer(
                            controller: _vlcController!,
                            aspectRatio: 16 / 9,
                            placeholder: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Container(
                            color: Colors.black,
                            child: Center(
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    )
                                  : Icon(
                                      Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                            ),
                          ),
                  ),
                  // Показываем иконку play только если видео не играет и не загружается
                  if (!_isPlaying && !_isLoading && _isInitialized)
                    Positioned(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  // Показываем иконку pause если видео играет
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
            )
          else
            // Для изображений используем простой Image.network без GestureDetector
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
