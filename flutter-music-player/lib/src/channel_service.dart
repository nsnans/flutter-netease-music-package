import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:music_player/music_player.dart';
import 'package:music_player/src/internal/serialization.dart';
import 'package:music_player/src/player/music_player.dart';

///
/// Interceptor when player try to load a media source
///
///
/// [mediaId] The id of media. [MediaMetadata.mediaId]
/// [fallbackUri] media origin uri.
///
/// @return media uri which should
///
typedef PlayUriInterceptor = Future<String?> Function(
    String? mediaId, String? fallbackUri);

typedef ImageLoadInterceptor = Future<Uint8List?> Function(
    MusicMetadata metadata);

class Config {
  final bool enableCache;

  final String? userAgent;

  /// For android only.
  /// pause player when the user has removed a task
  /// that comes from the service's application.
  final bool pauseWhenTaskRemoved;

  const Config({
    this.enableCache = false,
    this.userAgent,
    this.pauseWhenTaskRemoved = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'enableCache': enableCache,
      'userAgent': userAgent,
      'pauseWhenTaskRemoved': pauseWhenTaskRemoved,
    };
  }
}

///
/// handle background callback
///
Future runBackgroundService({
  Config config = const Config(),
  PlayUriInterceptor? playUriInterceptor,
  ImageLoadInterceptor? imageLoadInterceptor,
  PlayQueueInterceptor? playQueueInterceptor,
}) async {
  final log = Logger("runBackgroundService");
  WidgetsFlutterBinding.ensureInitialized();
  // decrease background image memory
  PaintingBinding.instance.imageCache.maximumSize = 20 << 20; // 20 MB
  const serviceChannel = MethodChannel("tech.soit.quiet/background_callback");
  final player = BackgroundMusicPlayer._internal(serviceChannel, MusicPlayer());
  playQueueInterceptor?._player = player;
  serviceChannel.setMethodCallHandler((call) async {
    log.fine("background: ${call.method} args = ${call.arguments}");
    switch (call.method) {
      case 'loadImage':
        if (imageLoadInterceptor != null) {
          return await imageLoadInterceptor(
              MusicMetadata.fromMap(call.arguments));
        }
        throw MissingPluginException();
      case 'getPlayUrl':
        if (playUriInterceptor != null) {
          final String? id = call.arguments['id'];
          final String? fallbackUrl = call.arguments['url'];
          return await playUriInterceptor(id, fallbackUrl);
        }
        throw MissingPluginException();
      case "onPlayNextNoMoreMusic":
        if (playQueueInterceptor != null) {
          return (await playQueueInterceptor.onPlayNextNoMoreMusic(
            createBackgroundQueue(call.arguments["queue"] as Map),
            PlayMode(call.arguments["playMode"] as int?),
          ))
              ?.toMap();
        }
        throw MissingPluginException();
      case "onPlayPreviousNoMoreMusic":
        if (playQueueInterceptor != null) {
          return (await playQueueInterceptor.onPlayPreviousNoMoreMusic(
            createBackgroundQueue(call.arguments["queue"] as Map),
            PlayMode(call.arguments["playMode"] as int?),
          ))
              .toMap();
        }
        throw MissingPluginException();
      default:
        throw MissingPluginException("can not hanle : ${call.method} ");
    }
  });
  serviceChannel.invokeMethod('updateConfig', config.toMap());
}

class BackgroundMusicPlayer extends Player {
  final MethodChannel _serviceChannel;

  final MusicPlayer _player;

  BackgroundMusicPlayer._internal(this._serviceChannel, this._player);

  @override
  ValueListenable<MusicMetadata?> get metadataListenable =>
      _player.metadataListenable;

  @override
  MusicPlayerValue get value => _player.value;

  @override
  ValueListenable<PlayMode> get playModeListenable =>
      _player.playModeListenable;

  @override
  ValueListenable<PlaybackState> get playbackStateListenable =>
      _player.playbackStateListenable;

  @override
  ValueListenable<PlayQueue> get queueListenable => _player.queueListenable;

  Future<void> insertToPlayQueue(List<MusicMetadata> list, int index) async {
    assert(() {
      if (index < 0 || index > value.queue.queue.length) {
        throw RangeError.range(index, 0, value.queue.queue.length);
      }
      return true;
    }());
    await _serviceChannel.invokeMethod("insertToPlayQueue", {
      "index": index,
      "list": list.map((e) => e.toMap()).toList(),
    });
  }
}

abstract class BackgroundPlayerCallback {
  void onPlaybackStateChanged(
      BackgroundMusicPlayer player, PlaybackState state);

  void onMetadataChange(BackgroundMusicPlayer player, MusicMetadata metadata);

  void onPlayQueueChanged(BackgroundMusicPlayer player, PlayQueue queue);

  void onPlayModeChanged(BackgroundMusicPlayer player, PlayMode playMode);
}

class PlayQueueInterceptor {
  void noImplement() {
    throw MissingPluginException();
  }

  BackgroundMusicPlayer? _player;

  BackgroundMusicPlayer? get player => _player;

  Future<MusicMetadata?> onPlayNextNoMoreMusic(
      BackgroundPlayQueue queue, PlayMode playMode) async {
    final list = await fetchMoreMusic(queue, playMode);
    debugPrint("fetched : $list");
    if (list.isNotEmpty) {
      await player!.insertToPlayQueue(list, player!.value.queue.queue.length);
      return list.first;
    } else {
      return null;
    }
  }

  ///
  /// Throw MissingPluginException() to use default playNext behavior.
  /// Default Behavior:
  ///   1. playMode is [PlayMode.sequence], auto play queue first item
  ///   2. playMode is [PlayMode.shuffle], auto generate a new shuffle list, then play from first.
  ///   3. playMode is [PlayMode.undefined(any)]. stop play.
  ///
  /// return null to stop play.
  ///
  Future<List<MusicMetadata>> fetchMoreMusic(
      BackgroundPlayQueue queue, PlayMode playMode) {
    throw MissingPluginException();
  }

  Future<MusicMetadata> onPlayPreviousNoMoreMusic(
      BackgroundPlayQueue queue, PlayMode playMode) {
    throw MissingPluginException();
  }
}

class BackgroundPlayQueue extends PlayQueue {
  /// shuffle mediaId list for shuffle playMode
  final List<String> shuffleQueue;

  BackgroundPlayQueue({
    required this.shuffleQueue,
    required String queueId,
    required String queueTitle,
    Map? extras,
    required List<MusicMetadata> queue,
  }) : super(
            queueId: queueId,
            queueTitle: queueTitle,
            extras: extras,
            queue: queue);
}
