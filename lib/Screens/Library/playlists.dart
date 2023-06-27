
import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/import_export_playlist.dart';
import 'package:blackhole/Screens/Library/liked.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PlaylistScreen extends StatefulWidget {
  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final Box settingsBox = Hive.box('settings');
  final List playlistNames =
      Hive.box('settings').get('playlistNames')?.toList() as List? ??
          ['Favorite Songs'];
  Map playlistDetails =
      Hive.box('settings').get('playlistDetails', defaultValue: {}) as Map;
  @override
  Widget build(BuildContext context) {
    if (!playlistNames.contains('Favorite Songs')) {
      playlistNames.insert(0, 'Favorite Songs');
      settingsBox.put('playlistNames', playlistNames);
    }

    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  AppLocalizations.of(context)!.playlists,
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.secondary,
                elevation: 0,
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 5),
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.createPlaylist),
                      leading: SizedBox.square(
                        dimension: 50,
                        child: Center(
                          child: Icon(
                            Icons.add_rounded,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ),
                      onTap: () async {
                        await showTextInputDialog(
                          context: context,
                          title:
                              AppLocalizations.of(context)!.createNewPlaylist,
                          initialText: '',
                          keyboardType: TextInputType.name,
                          onSubmitted: (String value) async {
                            final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
                            value.replaceAll(avoid, '').replaceAll('  ', ' ');
                            if (value.trim() == '') {
                              value = 'Playlist ${playlistNames.length}';
                            }
                            while (playlistNames.contains(value) ||
                                await Hive.boxExists(value)) {
                              // ignore: use_string_buffers
                              value = '$value (1)';
                            }
                            playlistNames.add(value);
                            settingsBox.put('playlistNames', playlistNames);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                   
                   
                    ValueListenableBuilder(
                      valueListenable: settingsBox.listenable(),
                      builder: (
                        BuildContext context,
                        Box box,
                        Widget? child,
                      ) {
                        final List playlistNamesValue = box.get(
                              'playlistNames',
                              defaultValue: ['Favorite Songs'],
                            )?.toList() as List? ??
                            ['Favorite Songs'];
                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: playlistNamesValue.length,
                          itemBuilder: (context, index) {
                            final String name =
                                playlistNamesValue[index].toString();
                            final String showName = playlistDetails
                                    .containsKey(name)
                                ? playlistDetails[name]['name']?.toString() ??
                                    name
                                : name;
                            return ListTile(
                              leading: (playlistDetails[name] == null ||
                                      playlistDetails[name]['imagesList'] ==
                                          null ||
                                      (playlistDetails[name]['imagesList']
                                              as List)
                                          .isEmpty)
                                  ? Card(
                                      elevation: 5,
                                      color: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: SizedBox(
                                        height: 50,
                                        width: 50,
                                        child: name == 'Favorite Songs'
                                            ? const Image(
                                                image: AssetImage(
                                                  'assets/cover.jpg',
                                                ),
                                              )
                                            : const Image(
                                                image: AssetImage(
                                                  'assets/album.png',
                                                ),
                                              ),
                                      ),
                                    )
                                  : Collage(
                                      imageList: playlistDetails[name]
                                          ['imagesList'] as List,
                                      showGrid: true,
                                      placeholderImage: 'assets/cover.jpg',
                                    ),
                              title: Text(
                                showName,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: playlistDetails[name] == null ||
                                      playlistDetails[name]['count'] == null ||
                                      playlistDetails[name]['count'] == 0
                                  ? null
                                  : Text(
                                      '${playlistDetails[name]['count']} ${AppLocalizations.of(context)!.songs}',
                                    ),
                              trailing: PopupMenuButton(
                                icon: const Icon(Icons.more_vert_rounded),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15.0),
                                  ),
                                ),
                                onSelected: (int? value) async {
                                  if (value == 1) {
                                    exportPlaylist(
                                      context,
                                      name,
                                      playlistDetails.containsKey(name)
                                          ? playlistDetails[name]['name']
                                                  ?.toString() ??
                                              name
                                          : name,
                                    );
                                  }
                                  if (value == 2) {
                                    sharePlaylist(
                                      context,
                                      name,
                                      playlistDetails.containsKey(name)
                                          ? playlistDetails[name]['name']
                                                  ?.toString() ??
                                              name
                                          : name,
                                    );
                                  }
                                  if (value == 0) {
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      '${AppLocalizations.of(context)!.deleted} $showName',
                                    );
                                    playlistDetails.remove(name);
                                    await settingsBox.put(
                                      'playlistDetails',
                                      playlistDetails,
                                    );
                                    await playlistNames.removeAt(index);
                                    await settingsBox.put(
                                      'playlistNames',
                                      playlistNames,
                                    );
                                    await Hive.openBox(name);
                                    await Hive.box(name).deleteFromDisk();
                                  }
                                  if (value == 3) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        final controller =
                                            TextEditingController(
                                          text: showName,
                                        );
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15.0),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!
                                                        .rename,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              TextField(
                                                autofocus: true,
                                                textAlignVertical:
                                                    TextAlignVertical.bottom,
                                                controller: controller,
                                                onSubmitted: (value) async {
                                                  Navigator.pop(context);
                                                  playlistDetails[name] == null
                                                      ? playlistDetails.addAll({
                                                          name: {
                                                            'name': value.trim()
                                                          }
                                                        })
                                                      : playlistDetails[name]
                                                          .addAll({
                                                          'name': value.trim()
                                                        });

                                                  await settingsBox.put(
                                                    'playlistDetails',
                                                    playlistDetails,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Theme.of(context)
                                                        .iconTheme
                                                        .color,
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .cancel,
                                              ),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                              ),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                playlistDetails[name] == null
                                                    ? playlistDetails.addAll({
                                                        name: {
                                                          'name': controller
                                                              .text
                                                              .trim()
                                                        }
                                                      })
                                                    : playlistDetails[name]
                                                        .addAll({
                                                        'name': controller.text
                                                            .trim()
                                                      });

                                                await settingsBox.put(
                                                  'playlistDetails',
                                                  playlistDetails,
                                                );
                                              },
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .ok,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                              .colorScheme
                                                              .secondary ==
                                                          Colors.white
                                                      ? Colors.black
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (name != 'Favorite Songs')
                                    PopupMenuItem(
                                      value: 3,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit_rounded),
                                          const SizedBox(width: 10.0),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .rename,
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (name != 'Favorite Songs')
                                    PopupMenuItem(
                                      value: 0,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete_rounded),
                                          const SizedBox(width: 10.0),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .delete,
                                          ),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 1,
                                    child: Row(
                                      children: [
                                        const Icon(MdiIcons.export),
                                        const SizedBox(width: 10.0),
                                        Text(
                                          AppLocalizations.of(context)!.export,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 2,
                                    child: Row(
                                      children: [
                                        const Icon(MdiIcons.share),
                                        const SizedBox(width: 10.0),
                                        Text(
                                          AppLocalizations.of(context)!.share,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await Hive.openBox(name);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LikedSongs(
                                      playlistName: name,
                                      showName:
                                          playlistDetails.containsKey(name)
                                              ? playlistDetails[name]['name']
                                                      ?.toString() ??
                                                  name
                                              : name,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
