import 'package:flutter/material.dart';
import 'package:music_player_example/player/player.dart';

class PlayPauseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final playbackState = PlayerStateWidget.of(context).playbackState;
    if (playbackState.state == PlayerState.playing) {
      return IconButton(
          icon: Icon(Icons.pause),
          onPressed: () {
            PlayerWidget.transportControls(context).pause();
          });
    } else if (playbackState.state == PlayerState.buffering) {
      return Center(
        child: Container(
          height: 24,
          width: 24,
          //to fit  IconButton min width 48
          margin: EdgeInsets.only(right: 12),
          padding: EdgeInsets.all(4),
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return IconButton(
          icon: Icon(Icons.play_arrow),
          tooltip: "play mode",
          onPressed: () {
            PlayerWidget.transportControls(context).play();
          });
    }
  }
}

class RepeatModelButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final MusicPlayerValue state = PlayerStateWidget.of(context);

    Widget icon;
    if (state.playMode == PlayMode.shuffle) {
      icon = const Icon(Icons.shuffle);
    } else if (state.playMode == PlayMode.single) {
      icon = const Icon(Icons.repeat_one);
    } else {
      icon = const Icon(Icons.repeat);
    }
    return IconButton(
        icon: icon,
        onPressed: () {
          PlayerWidget.transportControls(context)
              .setPlayMode(_getNext(state.playMode));
        });
  }

  static PlayMode _getNext(PlayMode playMode) {
    if (playMode == PlayMode.sequence) {
      return PlayMode.shuffle;
    } else if (playMode == PlayMode.shuffle) {
      return PlayMode.single;
    } else if (playMode == PlayMode.single) {
      return PlayMode.sequence;
    }
    throw "can not reach";
  }
}

class MusicPlaybackSpeedButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final MusicPlayerValue state = PlayerStateWidget.of(context);
    double speed = state.playbackState.speed;
    return TextButton(
      onPressed: () {
        PlayerWidget.transportControls(context)
            .setPlaybackSpeed(_getNext(speed));
      },
      child: Text("${speed}X"),
    );
  }

  double _getNext(double speed) {
    if (speed < 1) {
      return 1.0;
    } else if (speed == 1) {
      return 1.5;
    } else if (speed > 1) {
      return 0.5;
    } else {
      return 1;
    }
  }
}
