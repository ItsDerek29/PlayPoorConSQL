import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playbloc/views/player.dart';
import 'package:playbloc/widgets/drawer_menu.dart';
import 'package:playbloc/models/audio_item.dart';
import 'package:playbloc/models/audio_track.dart';
import 'package:playbloc/blocs/player_bloc.dart';
import 'package:playbloc/blocs/player_load_events.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:playbloc/utils/database_helper.dart';


class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  AudioPlayer? audioplayer;
  PlayerBloc? playerBloc;
  bool _isLoading = true;

  final List<AudioItem> seedTracks = [
    AudioItem("allthat.mp3", "All that", "Mayelo", "assets/allthat_colored.jpg"),
    AudioItem("love.mp3", "Love", "Diego", "assets/love_colored.jpg"),
    AudioItem("thejazzpiano.mp3", "Jazz Piano", "Jazira", "assets/thejazzpiano_colored.jpg"),
    AudioItem("eyeswithoutaface.mp3", "Eyes Without a Face", "Billy Idol", "assets/billyidol.jpg"),
    AudioItem("enjoythesilence.mp3", "Enjoy The Silence", "Depeche Mode", "assets/depechemode.jpg"),
    AudioItem("DonkeyKongCountry-AquaticAmbience.mp3", "Aquatic Ambience", "Nintendo", "assets/DonkeyKongAA.jpg"),
    AudioItem("DireDireDocks.mp3", "Dire, Dire Docks", "Nintendo", "assets/Mario64Logo.jpg"),
    AudioItem("EmeraldHillZone.mp3", "Emerald Hill Zone", "SEGA", "assets/Sonic2.jpg"),
  ];

  @override
  void initState() {
    super.initState();
    audioplayer = AudioPlayer();
    audioplayer?.setReleaseMode(ReleaseMode.release);
    _initApp();
  }

  Future<void> _initApp() async {
    await _initializeDatabase();
    final dbHelper = DatabaseHelper();
    final allTracks = await dbHelper.getAudioItems();

    playerBloc = PlayerBloc(
      audioPlayer: audioplayer!,
      items: allTracks,
    );

    playerBloc?.add(PlayerLoadEvent(0));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeDatabase() async {
    final dbHelper = DatabaseHelper();
    final count = await dbHelper.getAudioItemsCount();
    if (count == 0) {
      for (final track in seedTracks) {
        await dbHelper.insertAudioItem(track);
      }
      debugPrint("Database initialized with seed tracks.");
    }
  }

  @override
  void dispose() {
    playerBloc?.close();
    audioplayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || playerBloc == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return BlocProvider.value(
      value: playerBloc!,
      child: DrawerMenu(
        tracks: playerBloc!.items,
        child: Player(
          audioPlayer: audioplayer!,
          tracks: playerBloc!.items,
          bloc: playerBloc,
        ),
      ),
    );
  }
}
