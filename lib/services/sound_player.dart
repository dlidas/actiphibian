import 'package:audioplayers/audioplayers.dart';

class SoundPlayer {
  static final AudioPlayer player = AudioPlayer();

  static Future<void> playSound(String path) async {
    await player.stop();
    await player.play(AssetSource(path),
    );
  }
    
  static Future<void> dispose() async {
    await player.dispose();
  }
}