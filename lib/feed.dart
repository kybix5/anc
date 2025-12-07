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

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллер, но не запускаем автоматически
    if (widget.item['url_feed'].toString().endsWith('.mp4') ||
        widget.item['url_feed'].toString().contains('http')) {
      _vlcController = VlcPlayerController.network(
        widget.item['url_feed'],
        hwAcc: HwAcc.FULL,
        autoPlay: false, // Изменено на false
        options: VlcPlayerOptions(),
      );
      
      // Слушаем изменения состояния контроллера
      _vlcController?.addListener(_listener);
    }
  }

  void _listener() {
    if (_vlcController?.value.isInitialized ?? false) {
      if (!_isInitialized) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    }
  }

  void _togglePlay() async {
    if (_vlcController == null) return;
    
    if (!_isInitialized) {
      setState(() {
        _isLoading = true;
      });
      await _vlcController?.initialize();
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    }
    
    if (_isPlaying) {
      await _vlcController?.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _vlcController?.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    _vlcController?.removeListener(_listener);
    _vlcController?.stop();
    _vlcController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isVideo = widget.item['url_feed'].toString().endsWith('.mp4') ||
                  widget.item['url_feed'].toString().contains('.mp4');
    
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
                                  ? CircularProgressIndicator()
                                  : Icon(
                                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                            ),
                          ),
                  ),
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
                ],
              ),
            )
          else
            Image.network(
              widget.item['url_feed'],
              fit: BoxFit.cover,
              height: widget.height_n / 3,
              width: double.infinity,
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
