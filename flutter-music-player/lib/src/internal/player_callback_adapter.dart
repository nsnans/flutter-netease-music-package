import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:music_player/music_player.dart';
import 'package:music_player/src/player/music_player_callback.dart';

import 'ext_copy.dart';
import 'serialization.dart';

mixin ChannelPlayerCallbackAdapter on ValueNotifier<MusicPlayerValue>
    implements MusicPlayerCallback {
  bool handleRemoteCall(MethodCall call) {
    switch (call.method) {
      case 'onPlaybackStateChanged':
        onPlaybackStateChanged(createPlaybackState(call.arguments));
        break;
      case 'onMetadataChanged':
        onMetadataChange(MusicMetadata.fromMap(call.arguments));
        break;
      case 'onPlayQueueChanged':
        onPlayQueueChanged(PlayQueue.fromMap(call.arguments));
        break;
      case 'onPlayModeChanged':
        onPlayModeChanged(PlayMode(call.arguments as int?));
        break;
      default:
        return false;
    }
    return true;
  }

  @override
  void onMetadataChange(MusicMetadata metadata) {
    value = value.copy(metadata: metadata);
  }

  @override
  void onPlayModeChanged(PlayMode playMode) {
    value = value.copy(playMode: playMode);
  }

  @override
  void onPlayQueueChanged(PlayQueue queue) {
    value = value.copy(queue: queue);
  }

  @override
  void onPlaybackStateChanged(PlaybackState state) {
    value = value.copy(state: state);
  }
}
