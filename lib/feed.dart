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
  VlcPlayerController? _vlcController;
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
    
    // Создаем контроллер только для видео, но не инициализируем сразу
    if (isVideo) {
      _createController();
    }
  }

  void _createController() {
    try {
      _vlcController = VlcPlayerController.network(
        widget.item['url_feed'],
        autoPlay: false,
        options: VlcPlayerOptions(),
      );
      
      // Слушаем изменения состояния контроллера
      _vlcController?.addListener(_listener);
    } catch (e) {
      print("Ошибка создания контроллера: $e");
      _vlcController = null;
    }
  }

  void _listener() {
    if (_isDisposed || !mounted) return;
    
    final controller = _vlcController;
    if (controller != null && controller.value.isInitialized) {
      if (!_isInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) {
            setState(() {
              _isInitialized = true;
              _isLoading = false;
            });
          }
        });
      }
    }
  }

  Future<void> _initializeVideo() async {
    if (!isVideo || _isDisposed || !mounted) return;
    
    if (_vlcController == null) {
      _createController();
    }
    
    if (_vlcController == null) return;
    
    if (!_isInitialized) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      
      try {
        await _vlcController!.initialize();
        
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
    }
  }

  void _togglePlay() async {
    if (!isVideo || _isDisposed || !mounted) return;
    
    if (!_isInitialized) {
      await _initializeVideo();
      return;
    }
    
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

  @override
  void didUpdateWidget(FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Если URL изменился, пересоздаем контроллер
    if (oldWidget.item['url_feed'] != widget.item['url_feed']) {
      if (_vlcController != null) {
        _disposeController();
      }
      if (isVideo) {
        _createController();
        setState(() {
          _isInitialized = false;
          _isPlaying = false;
          _isLoading = false;
        });
      }
    }
  }

  void _disposeController() {
    if (_vlcController != null) {
      try {
        _vlcController?.removeListener(_listener);
        if (_isPlaying) {
          _vlcController?.pause();
        }
        _vlcController?.dispose();
      } catch (e) {
        print("Ошибка при dispose контроллера: $e");
      }
      _vlcController = null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeController();
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
              child: Container(
                height: widget.height_n / 3,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Видео плеер
                    if (_isInitialized && _vlcController != null)
                      VlcPlayer(
                        controller: _vlcController!,
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
                    
                    // Превью или иконка загрузки
                    if (!_isInitialized || _isLoading)
                      Container(
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
                    
                    // Иконка play поверх видео (когда видео пауза)
                    if (_isInitialized && !_isPlaying && !_isLoading)
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
                    
                    // Иконка pause (когда видео играет)
                    if (_isInitialized && _isPlaying && !_isLoading)
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
