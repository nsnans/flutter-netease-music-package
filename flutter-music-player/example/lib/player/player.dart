import 'package:flutter/material.dart';
import 'package:music_player/music_player.dart';
import 'package:overlay_support/overlay_support.dart';

export 'package:music_player/music_player.dart';

class PlayerWidget extends StatefulWidget {
  final Widget child;

  const PlayerWidget({Key? key, required this.child}) : super(key: key);

  static TransportControls transportControls(BuildContext context) {
    return player(context).transportControls;
  }

  static MusicPlayer player(BuildContext context) {
    final state = context.findAncestorStateOfType<_PlayerWidgetState>();
    return state!.player;
  }

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

extension PlayerContext on BuildContext {
  TransportControls get transportControls =>
      PlayerWidget.transportControls(this);

  MusicPlayer get player => PlayerWidget.player(this);

  MusicPlayerValue get listenPlayerValue => PlayerStateWidget.of(this);
}

class _PlayerWidgetState extends State<PlayerWidget> {
  late MusicPlayer player;

  @override
  void initState() {
    super.initState();
    player = MusicPlayer()
      ..addListener(() {
        setState(() {});
      });
    player.playbackStateListenable.addListener(() {
      if (player.playbackStateListenable.value.error != null) {
        toast("""
        play ${player.metadataListenable.value?.title} failed. 
        error:\n${player.playbackStateListenable.value.error}
        """, duration: Toast.LENGTH_LONG);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    player.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlayerStateWidget(child: widget.child, state: player.value);
  }
}

class PlayerStateWidget extends InheritedWidget {
  final MusicPlayerValue state;

  const PlayerStateWidget({
    Key? key,
    required this.state,
    required Widget child,
  }) : super(key: key, child: child);

  static MusicPlayerValue of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<PlayerStateWidget>();
    return widget!.state;
  }

  @override
  bool updateShouldNotify(PlayerStateWidget old) {
    return old.state != state;
  }
}
