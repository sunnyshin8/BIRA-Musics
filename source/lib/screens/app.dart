
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {

  final _audioQuery = OnAudioQuery();

  late SongModel? previousSong;
  late SongModel? playingSong;
  late SongModel? nextSong;

  late Future<List<SongModel>> _songs;
  late Future<PlaylistModel> _playlist;

  List<int> _favorites = <int>[];
  var playError = false;
  late AudioPlayer audioPlayer = AudioPlayer();
  var _isShowingWidgetOutline = false;
  var _barHeight = 3.0;
  var _barCapShape = BarCapShape.round;
  var _labelLocation = TimeLabelLocation.below;
  var _labelType = TimeLabelType.totalTime;
  TextStyle? _labelStyle = TextStyle(fontSize: 20, color: Colors.white);
  var _thumbRadius = 10.0;
  var _labelPadding = 0.0;
  var _thumbCanPaintOutsideBar = true;
  Color? _baseBarColor = Colors.grey.withOpacity(0.2);
  Color? _progressBarColor = Colors.purple;
  Color? _bufferedBarColor = Colors.purpleAccent.withOpacity(0.2);
  Color? _thumbColor = Colors.purple;
  Color? _thumbGlowColor = Colors.green.withOpacity(0.3);
  Color? _color = Colors.white;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    requestPermission();
    previousSong = null;
    playingSong = null;
    nextSong = null;
    _songs = _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    _audioQuery.createPlaylist("Your Playlist");
    _playlist = getPlaylist();
  }

  void requestPermission() async {
    if (await Permission.storage
        .request()
        .isGranted) {
      print("Permission Granted");
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BIRA Musics'),
        backgroundColor: Colors.purple,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
        selectedIndex: currentIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.featured_play_list_outlined),
            selectedIcon: Icon(Icons.featured_play_list),
            label: 'Playlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_library_outlined),
            selectedIcon: Icon(Icons.local_library),
            label: 'Library',
          ),
        ],
      ),
      body: <Widget>[
        Container(
          color: Colors.black,
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 100,
                        child: Icon(Icons.album, size: 75),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          playingSong?.title ?? "No Song Playing",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(playingSong != null
                          ? playingSong!.artist.toString()
                          : '--------',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        overflow: TextOverflow.fade,
                        maxLines: 1,),
                      const SizedBox(height: 20),
                      Container(
                        decoration: _widgetBorder(),
                        child: _progressBar(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _previousButton()),
                          Expanded(child: _buttons()),
                          Expanded(child: _nextButton()),
                          // ha, guests aaye hai
                        ],
                      )
                    ],

                  )
              )
            ],
          ),
        ),
        _playListContainer(),
        Container(
          color: Colors.black,
          child: Column(
              children: <Widget>[
                Expanded(
                  child: FutureBuilder<List<SongModel>>(
                    future: _songs,
                    builder: (context, snapshot) {
                      if (snapshot.data == null) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No Songs Found'),
                        );
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.album, color: Colors.white,),
                            title: Text(snapshot.data![index].title, style: const TextStyle(color: Colors.white),),
                            subtitle: Text(snapshot.data![index].artist ?? '', style: const TextStyle(color: Colors.white),),
                            onTap: () {
                              if (playingSong != snapshot.data![index]) {
                                startSong(snapshot.data![index].uri);
                              }
                              if (index != 0) {
                                previousSong = snapshot.data![index - 1];
                              } else {
                                previousSong = null;
                              }
                              playingSong = snapshot.data![index];
                              if (index != snapshot.data!.length - 1) {
                                nextSong = snapshot.data![index + 1];
                              } else {
                                nextSong = null;
                              }
                            },
                            trailing: Wrap(
                                spacing: 0, // space between two icons
                                children: <Widget>[
                                  PopupMenuButton(
                                      icon: Icon(Icons.add, color: _color),
                                      itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<int>>[
                                        PopupMenuItem<int>(
                                          value: 1,
                                          child: const Text('Add to playlist'),
                                          onTap: () {
                                            setState(() {
                                              // TODO: add to playlist
                                            });
                                          },
                                        ),
                                      ]
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _favorites.contains(index)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                    ),
                                    color: _color,
                                    onPressed: () {
                                      setState(() {
                                        if (_favorites.contains(index)) {
                                          _favorites.remove(index);
                                        } else {
                                          _favorites.add(index);
                                        }
                                      });
                                    },

                                  ),
                                ]
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: _widgetBorder(),
                  child: _songDetails(),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: _widgetBorder(),
                  child: _progressBar(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _previousButton()),
                    Expanded(child: _buttons()),
                    Expanded(child: _nextButton()),
                    // ha, guests aaye hai
                  ],
                )
              ]
          ),
        ),
      ][currentIndex],
    );
  }

  startSong(String? uri) async {
    try {
      audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(uri!),
        ),
      );
      audioPlayer.play();
    } on Exception catch (e) {
      print(e);
    }
  }

  BoxDecoration _widgetBorder() {
    return BoxDecoration(
      border: _isShowingWidgetOutline
          ? Border.all(color: Colors.red)
          : Border.all(color: Colors.transparent),
    );
  }

  // Container

  StreamBuilder<Duration> _progressBar() {
    return StreamBuilder<Duration>(
      stream: audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = audioPlayer.position;
        final bufferedPosition = audioPlayer.bufferedPosition;
        final total = audioPlayer.duration ?? Duration.zero;
        return ProgressBar(
          progress: position,
          buffered: bufferedPosition,
          total: total,
          onSeek: audioPlayer.seek,
          onDragUpdate: (details) {
            debugPrint('${details.timeStamp}, ${details.localPosition}');
          },
          barHeight: _barHeight,
          baseBarColor: _baseBarColor,
          progressBarColor: _progressBarColor,
          bufferedBarColor: _bufferedBarColor,
          thumbColor: _thumbColor,
          thumbGlowColor: _thumbGlowColor,
          barCapShape: _barCapShape,
          thumbRadius: _thumbRadius,
          thumbCanPaintOutsideBar: _thumbCanPaintOutsideBar,
          timeLabelLocation: _labelLocation,
          timeLabelType: _labelType,
          timeLabelTextStyle: _labelStyle,
          timeLabelPadding: _labelPadding,
        );
      },
    );
  }
  
  

  Widget _previousButton() {
    return IconButton(
      icon: const Icon(Icons.skip_previous),
      color: Colors.white,
      iconSize: 40,
      onPressed: () {
        if (previousSong != null) {
          _songs.then((value) {
            nextSong = playingSong;
            playingSong = previousSong;
            if (value.indexOf(previousSong!) != 0) {
              previousSong = value[value.indexOf(previousSong!) - 1];
            } else {
              previousSong = null;
            }
            startSong(playingSong!.uri);
          });
        }
      },
    );
  }

  Widget _nextButton() {
    return IconButton(
      icon: const Icon(Icons.skip_next),
      color: Colors.white,
      iconSize: 40,
      onPressed: () {
        if (nextSong != null) {
          _songs.then((value) {
            previousSong = playingSong;
            playingSong = nextSong;
            if (value.indexOf(nextSong!) != value.length - 1) {
              nextSong = value[value.indexOf(nextSong!) + 1];
            } else {
              nextSong = null;
            }
            startSong(playingSong!.uri);
          });
        }
      },
    );
  }

  StreamBuilder<PlayerState> _buttons() {
    return StreamBuilder<PlayerState>(
      stream: audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            width: 40.0,
            height: 40.0,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          if (playError) {
            return IconButton(
              icon: const Icon(Icons.priority_high, color: Colors.red,),
              iconSize: 40.0,
              onPressed: () {
                // Navigator.push(context, MaterialPageRoute(builder: (context) => this.build(context)));
              },
            );
          }
          return IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white,),
            iconSize: 40.0,
            onPressed: () {
              if (playingSong != null) {
                audioPlayer.play();
              }
              },
          );
        } else if (processingState != ProcessingState.completed) {
          return IconButton(
            icon: const Icon(Icons.pause, color: Colors.white),
            iconSize: 40.0,
            onPressed: () {
              audioPlayer.pause();
              },
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.replay, color: Colors.white),
            iconSize: 40.0,
            onPressed: () =>
                audioPlayer.seek(Duration.zero),
          );
        }
      },
    );
  }

  Container _playListContainer() {
    return Container(
      color: Colors.black,
      child: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<PlaylistModel>(
              future: _playlist,
              builder: (context, snapshot) {
                // if (snapshot.hasData) {
                //   return ListView.builder(
                //     itemCount: snapshot.data!.getMap!.length,
                //     itemBuilder: (context, index) {
                //       return ListTile(
                //         title: Text(snapshot.data!.data??""),
                //         subtitle: Text(snapshot.data!.playlist),
                //         onTap: () {
                //
                //         },
                //       );
                //     },
                //   );
                // }
                return const Text("Error getting playlist", style: TextStyle(color: Colors.white),);
              },
            ),),
          const SizedBox(height: 20),
          Container(
            decoration: _widgetBorder(),
            child: _songDetails(),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: _widgetBorder(),
            child: _progressBar(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _previousButton()),
              Expanded(child: _buttons()),
              Expanded(child: _nextButton()),
            ],
          )
        ],
      ),
    );
  }

  Future<PlaylistModel> getPlaylist() async {
    List<dynamic> playlist = await _audioQuery.queryWithFilters(
      "Your Playlist", WithFiltersType.PLAYLISTS, args: PlaylistsArgs.PLAYLIST,
    );

    return playlist.toPlaylistModel().first;
  }

  _songDetails() {
    return Text('${playingSong == null ? "-------" : playingSong?.title}', style: const TextStyle(color: Colors.white),);
  }


}

class DurationState {
  const DurationState({required this.progress, required this.buffered, required this.total});
  final Duration progress;
  final Duration buffered;
  final Duration total;
}