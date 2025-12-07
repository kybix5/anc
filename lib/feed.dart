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
  bool _hasError = false;

  bool get isVideo {
    final url = widget.item['url_feed'].toString().toLowerCase();
    // Более точная проверка видео файлов
    return url.endsWith('.mp4') || 
           url.contains('.mp4?') || 
           url.endsWith('.mov') ||
           url.endsWith('.avi') ||
           url.endsWith('.wmv') ||
           url.endsWith('.flv') ||
           url.endsWith('.webm') ||
           url.contains('video') && (url.contains('mp4') || url.contains('mov'));
  }

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _hasError = false;
    
    // Только создаем контроллер, НЕ инициализируем сразу
    if (isVideo) {
      _createController();
    }
  }

  void _createController() {
    try {
      _vlcController = VlcPlayerController.network(
        widget.item['url_feed'],
        autoPlay: false,
        options: VlcPlayerOptions(
          // Добавляем дополнительные опции для стабильности
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(3000),
            VlcAdvancedOptions.liveCaching(3000),
          ]),
        ),
      );
      
      // Обработчик событий
      _vlcController?.addListener(_videoListener);
    } catch (e) {
      print("Ошибка создания контроллера VLC: $e");
      _vlcController = null;
      _hasError = true;
    }
  }

  void _videoListener() {
    if (_isDisposed || !mounted) return;
    
    final controller = _vlcController;
    if (controller == null) return;
    
    // Проверяем инициализацию
    if (controller.value.isInitialized && !_isInitialized) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) {
            setState(() {
              _isInitialized = true;
              _isLoading = false;
              _hasError = false;
            });
          }
        });
      }
    }
    
    // Проверяем ошибки
    if (controller.value.hasError) {
      print("Ошибка видео: ${controller.value.errorMessage}");
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) {
            setState(() {
              _hasError = true;
              _isLoading = false;
              _isPlaying = false;
            });
          }
        });
      }
    }
  }

  Future<void> _initializeVideo() async {
    if (!isVideo || _isDisposed || !mounted || _hasError) return;
    
    if (_vlcController == null) {
      _createController();
      if (_vlcController == null) {
        setState(() {
          _hasError = true;
        });
        return;
      }
    }
    
    if (!_isInitialized) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      try {
        // Задержка для стабильности инициализации
        await Future.delayed(Duration(milliseconds: 100));
        
        await _vlcController!.initialize();
        
        if (mounted && !_isDisposed) {
          setState(() {
            _isInitialized = true;
            _isLoading = false;
            _isPlaying = true;
            _hasError = false;
          });
        }
      } catch (e, stackTrace) {
        print("Ошибка инициализации видео: $e");
        print("Stack trace: $stackTrace");
        
        if (mounted && !_isDisposed) {
          setState(() {
            _hasError = true;
            _isLoading = false;
            _isPlaying = false;
          });
        }
        
        // Пробуем пересоздать контроллер
        _disposeController();
        _createController();
      }
    }
  }

  void _togglePlay() async {
    if (!isVideo || _isDisposed || !mounted) return;
    
    if (_hasError) {
      // Пробуем сбросить ошибку и начать заново
      _disposeController();
      _createController();
      setState(() {
        _hasError = false;
        _isInitialized = false;
        _isPlaying = false;
      });
    }
    
    if (!_isInitialized) {
      await _initializeVideo();
      return;
    }
    
    if (_vlcController == null) return;
    
    try {
      if (_isPlaying) {
        await _vlcController?.pause();
        if (mounted && !_isDisposed) {
          setState(() {
            _isPlaying = false;
          });
        }
      } else {
        // Проверяем, что видео готово к воспроизведению
        if (_vlcController!.value.isInitialized && !_vlcController!.value.hasError) {
          await _vlcController?.play();
          if (mounted && !_isDisposed) {
            setState(() {
              _isPlaying = true;
            });
          }
        } else {
          // Если есть проблема, переинициализируем
          await _initializeVideo();
        }
      }
    } catch (e) {
      print("Ошибка переключения воспроизведения: $e");
      setState(() {
        _hasError = true;
      });
    }
  }

  void _disposeController() {
    if (_vlcController != null) {
      try {
        _vlcController?.removeListener(_videoListener);
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
                    // Видео плеер (только если инициализирован и нет ошибки)
                    if (_isInitialized && _vlcController != null && !_hasError)
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
                    
                    // Состояние загрузки
                    if (_isLoading)
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    
                    // Состояние ошибки
                    if (_hasError)
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Ошибка загрузки видео',
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _togglePlay,
                                child: Text('Попробовать снова'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Иконка play (если не инициализировано, нет ошибки и не загружается)
                    if (!_isInitialized && !_isLoading && !_hasError)
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    
                    // Иконка play поверх видео (когда видео на паузе)
                    if (_isInitialized && !_isPlaying && !_isLoading && !_hasError)
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
                    if (_isInitialized && _isPlaying && !_isLoading && !_hasError)
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
