import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class CameraScreenWidget extends StatefulWidget {
  const CameraScreenWidget({super.key});

  @override
  _CameraScreenWidgetState createState() => _CameraScreenWidgetState();
}

class _CameraScreenWidgetState extends State<CameraScreenWidget> {
  bool _isPlaying = true;
  bool _isError = false; // Новое состояние для отслеживания ошибок

  final VlcPlayerController _videoPlayerController = VlcPlayerController.network(
    //'rtsp://46.16.226.6:554/user=user&password=&channel=1&stream=0',
    'http://46.16.226.6:8090',
    //'http://media.w3.org/2010/05/bunny/movie.mp4',
    hwAcc: HwAcc.full,
    autoPlay: true,
    options: VlcPlayerOptions(),
  );

  Color _buttonColorPlay = Colors.green;
  Color _buttonColorPause = Colors.black;

  @override
  void initState() {
    super.initState();
    // Добавляем слушателя для отслеживания состояния потока
    _videoPlayerController.addListener(() {
      if (_videoPlayerController.value.hasError) {
        setState(() {
          _isError = true; // Устанавливаем состояние ошибки
        });
      }
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  void _playVideo() {
    setState(() {
      _isError = false; // Сбрасываем состояние ошибки при попытке воспроизведения
      _buttonColorPlay = Colors.green;
      _buttonColorPause = Colors.black;
      _isPlaying = true;
      _videoPlayerController.play();
    });
  }

  void _pauseVideo() {
    setState(() {
      _buttonColorPause = Colors.green;
      _buttonColorPlay = Colors.black;
      _isPlaying = false;
      _videoPlayerController.pause();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Камера')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isError) // Если есть ошибка, показываем сообщение
              const Text(
                'Ошибка загрузки видео',
                style: TextStyle(color: Colors.red, fontSize: 20),
              )
            else
              Center(
                child: VlcPlayer(
                  controller: _videoPlayerController,
                  aspectRatio: 16 / 9,
                  placeholder: const Center(child: CircularProgressIndicator()),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _isError ? null : _playVideo, // Деактивируем кнопку воспроизведения при ошибке
                  child: Icon(Icons.play_arrow, size: 28, color: _buttonColorPlay),
                ),
                TextButton(
                  onPressed: _isError ? null : _pauseVideo, // Деактивируем кнопку паузы при ошибке
                  child: Icon(Icons.pause, size: 28, color: _buttonColorPause),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
