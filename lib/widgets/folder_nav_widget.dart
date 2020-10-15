/*This file is part of Medito App.

Medito App is free software: you can redistribute it and/or modify
it under the terms of the Affero GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Medito App is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Affero GNU General Public License for more details.

You should have received a copy of the Affero GNU General Public License
along with Medito App. If not, see <https://www.gnu.org/licenses/>.*/

import 'package:Medito/audioplayer/media_lib.dart';
import 'package:Medito/audioplayer/player_widget.dart';
import 'package:Medito/data/page.dart';
import 'package:Medito/tracking/tracking.dart';
import 'package:Medito/utils/colors.dart';
import 'package:Medito/utils/utils.dart';
import 'package:Medito/viewmodel/main_view_model.dart';
import 'package:Medito/viewmodel/model/list_item.dart';
import 'package:Medito/widgets/text_file_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_bar_widget.dart';
import 'session_options_screen.dart';
import 'list_item_file_widget.dart';
import 'list_item_image_widget.dart';
import 'loading_list_widget.dart';

class FolderStateless extends StatelessWidget {
  FolderStateless({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FolderNavWidget();
  }
}

class FolderNavWidget extends StatefulWidget {
  FolderNavWidget(
      {Key key, this.firstId, this.firstTitle, this.title})
      : super(key: key);

  final String title;
  final String firstId;
  final String firstTitle;

  @override
  _FolderNavWidgetState createState() => _FolderNavWidgetState();
}

class _FolderNavWidgetState extends State<FolderNavWidget>
    with TickerProviderStateMixin {
  final _viewModel = new SubscriptionViewModelImpl();
  Future<List<ListItem>> listFuture;

  String textFileFromFuture = "";

  BuildContext scaffoldContext;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    listFuture = _viewModel.getPageChildren(id: widget.firstId);

    if (widget.firstTitle != null && widget.firstTitle.isNotEmpty) {
      _viewModel.updateNavData(
          ListItem("Home", "app+content", null, parentId: "app+content"));
      _viewModel
          .updateNavData(ListItem(widget.firstTitle, widget.firstId, null));
    }

  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      body: new Builder(
        builder: (BuildContext context) {
          scaffoldContext = context;
          return buildSafeAreaBody();
        },
      ),
    );
  }

  Widget buildSafeAreaBody() {
    checkConnectivity().then((connected) {
      if (!connected) {
        createSnackBar('Check your connectivity', scaffoldContext);
      }
    });

    return SafeArea(
      bottom: false,
      maintainBottomViewPadding: false,
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                  child: Stack(
                children: <Widget>[
                  getListView(),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget getListView() {
    return RefreshIndicator(
      color: MeditoColors.lightColor,
      backgroundColor: MeditoColors.moonlight,
      child: FutureBuilder(
          future: listFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.none) {
              return Text(
                "No connection. Please try again later",
                style: Theme.of(context).textTheme.headline3,
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.hasData == false ||
                snapshot.hasData == null) {
              return LoadingListWidget();
            }

            return new ListView.builder(
                itemCount:
                    1 + (snapshot.data == null ? 0 : snapshot.data.length),
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int i) {
                  if (i == 0) {
                    return MeditoAppBarWidget(
                      title: widget.firstTitle ?? widget.title,
                      backPressed: _backPressed,
                    );
                  }
                  return Column(
                    children: <Widget>[
                      getChildForListView(snapshot.data[i - 1]),
                    ],
                  );
                });
          }),
      onRefresh: _onPullToRefresh,
    );
  }

  Future<void> _onPullToRefresh() async {
    setState(() {
      listFuture = _viewModel.getPageChildren(
          id: widget.firstId, skipCache: true);
    });
  }

  void folderTap(ListItem i) {
    Tracking.trackEvent(Tracking.FOLDER_TAPPED, Tracking.SCREEN_LOADED, i.id);
    //if you tapped on a folder

    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: '/nav'),
        builder: (c) {
          return FolderNavWidget(
            firstId: i.id,
            title: i.title,
          );
        },
      ),
    );
  }

  void fileTap(ListItem item) {
    if (item.fileType == FileType.audiosethourly ||
        item.fileType == FileType.audiosetdaily) {
      Tracking.trackEvent(Tracking.FILE_TAPPED, Tracking.AUDIO_OPENED, item.id);
      _showPlayerBottomSheet(item);
    } else if (item.fileType == FileType.audio) {
      Tracking.trackEvent(Tracking.FILE_TAPPED, Tracking.AUDIO_OPENED, item.id);
      _showPlayerBottomSheet(item);
    } else if (item.fileType == FileType.both) {
      Tracking.trackEvent(Tracking.FILE_TAPPED, Tracking.AUDIO_OPENED, item.id);
      _showPlayerBottomSheet(item);
    } else if (item.fileType == FileType.text) {
      Tracking.trackEvent(
          Tracking.FILE_TAPPED, Tracking.TEXT_ONLY_OPENED, item.id);
      _openTextFile(item);
    }
  }

  _showPlayerBottomSheet(ListItem listItem) {
    _viewModel.currentlySelectedFile = listItem;

    var data;
    if (listItem.fileType == FileType.audiosetdaily ||
        listItem.fileType == FileType.audiosethourly) {
      data = _viewModel.getAudioFromSet(
          id: listItem.id, timely: listItem.fileType);
    } else {
      data = _viewModel.getAudioData(id: listItem.id);
    }

    final result = Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionOptionsScreen(
            title: listItem.title,
            onBeginPressed: _showPlayer,
            data: data,
          ),
        )).then((value) {
      setState(() {});
      return null;
    });

    if (result == "error") {
      _onPullToRefresh();
    }
  }

  _showPlayer(
      Files fileTapped,
      Illustration coverArt,
      dynamic primaryColor,
      String title,
      String description,
      String contentText,
      String textColor,
      String bgMusic, int durationAsMiliseconds) async {
    await _viewModel
        .getAttributions(fileTapped.attributions)
        .then((attributionsContent) async =>
            await MediaLibrary.saveMediaLibrary(
                description,
                title,
                fileTapped,
                coverArt,
                textColor,
                primaryColor,
                bgMusic,
                durationAsMiliseconds,
                _viewModel.currentlySelectedFile,
                attributionsContent))
        .then((value) {
      start(primaryColor).then((value) {
        Navigator.push(context, MaterialPageRoute(builder: (c) {
          return PlayerWidget();
        })).then((value) {
          setState(() {});
          return null;
        });
        return null;
      });
    });
  }

  Widget getFileListItem(ListItem item) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: new ListItemWidget(
        item: item,
      ),
    );
  }

  Widget getChildForListView(ListItem item) {
    if (item.type == ListItemType.folder) {
      return InkWell(
          onTap: () => folderTap(item),
          splashColor: MeditoColors.moonlight,
          child: getFileListItem(item));
    } else if (item.type == ListItemType.file) {
      return InkWell(
          onTap: () => fileTap(item),
          splashColor: MeditoColors.moonlight,
          child: getFileListItem(item));
    } else {
      return SizedBox(
          width: 300, child: new ImageListItemWidget(src: item.url));
    }
  }

  void _backPressed(String id) {
    Navigator.pop(context);
  }

  void _openTextFile(ListItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) {
          return TextFileWidget(
            firstTitle: item.title,
            text: item.contentText,
          );
        },
      ),
    );
  }
}
