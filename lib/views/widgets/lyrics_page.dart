import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:music_player/models/lyrics.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../models/music.dart';

class LyricsPage extends StatefulWidget {
  final Music music;
  final AudioPlayer player;
  const LyricsPage({super.key, required this.music, required this.player});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  List<Lyrics>? lyrics;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController = ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  final ScrollOffsetListener scrollOffsetListener = ScrollOffsetListener.create();

  StreamSubscription? streamSubscription;

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    streamSubscription = widget.player.onPositionChanged.listen((duration) {
      DateTime dt = DateTime(1970, 1, 1).copyWith(
        hour: duration.inHours,
        minute: duration.inMinutes.remainder(60),
        second: duration.inSeconds.remainder(60)
      );

      if(lyrics != null) {
        for(int i=0; i<lyrics!.length; i++) {
          if(i > 4 && lyrics![i].timeStamp.isAfter(dt)) {
            itemScrollController.scrollTo(
                index: i - 3,
                duration: const Duration(milliseconds: 600));
            break;
          }
        }
      }
    });

    get(Uri.parse('https://paxsenixofc.my.id/server/getLyricsMusix.php?q=${widget.music.songName} ${widget.music.artistName}&type=default')).then((response) {
      String data = response.body;
      lyrics = data
          .split('\n')
          .map((e) => Lyrics(e.split(' ').sublist(1).join(' '),
              DateFormat("[mm:ss.SS]").parse(e.split(' ')[0])))
          .toList();
      setState(() {});
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.music.songColor,
      body: lyrics!=null ? SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0)
              .copyWith(top: 20),
          child: StreamBuilder<Duration> (
            stream: widget.player.onPositionChanged,
            builder: (context, snapshots) {
              return ScrollablePositionedList.builder(
                  itemCount: lyrics!.length,
                  itemBuilder: (context, index) {
                    Duration duration =
                        snapshots.data ?? const Duration(seconds: 0);
                    DateTime dt = DateTime(1970, 1, 1).copyWith(
                      hour: duration.inHours,
                      minute: duration.inMinutes.remainder(60),
                      second: duration.inSeconds.remainder(60)
                    );

                    return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text (
                          lyrics![index].words,
                          style: TextStyle(
                            color: lyrics![index].timeStamp.isAfter(dt)
                                ? Colors.white38
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    );
                  },
                  itemScrollController: itemScrollController,
                  scrollOffsetController: scrollOffsetController,
                  itemPositionsListener: itemPositionsListener,
                  scrollOffsetListener: scrollOffsetListener,
              );
            }

          ),
        ),
      )
          :const SizedBox(),
    );
  }
}
