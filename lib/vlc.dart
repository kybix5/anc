import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class CameraScreenWidget extends StatefulWidget {
  const CameraScreenWidget({super.key});

  @override
  _CameraScreenWidgetState createState() => _CameraScreenWidgetState();
}

class _CameraScreenWidgetState extends State<CameraScreenWidget> {
  bool _isPlaying = true;

  final VlcPlayerController _videoPlayerController =
      VlcPlayerController.network(
    'rtsp://46.16.226.6:554/user=user&password=&channel=1&stream=0',
    hwAcc: HwAcc.full,
    autoPlay: true,
    options: VlcPlayerOptions(),
  );

  Color _buttonColorPlay = Colors.green;
  Color _buttonColorPause = Colors.black;

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  void _playVideo() {
    setState(() {
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
        appBar: AppBar(title: const Text('Kамера')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                    onPressed: _playVideo,
                    child: Icon(Icons.play_arrow,
                        size: 28, color: _buttonColorPlay),
                  ),
                  TextButton(
                    onPressed: _pauseVideo,
                    child:
                        Icon(Icons.pause, size: 28, color: _buttonColorPause),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
