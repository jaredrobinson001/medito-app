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

import 'dart:async';

import 'package:Medito/audioplayer/medito_audio_handler.dart';
import 'package:Medito/utils/colors.dart';
import 'package:Medito/utils/navigation_extra.dart';
import 'package:Medito/utils/stats_utils.dart';
import 'package:Medito/utils/text_themes.dart';
import 'package:Medito/widgets/home/home_wrapper_widget.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audioplayer/audio_inherited_widget.dart';
import 'network/auth.dart';
import 'utils/colors.dart';

SharedPreferences sharedPreferences;


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sharedPreferences = await SharedPreferences.getInstance();

  var _audioHandler = await AudioService.init(
    builder: () => MeditoAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.medito.app.channel.audio',
      androidNotificationChannelName: 'Medito Session',
    ),
  );

  _audioHandler.customEvent.stream.listen((event) async {
    if (event == STATS) {
      await updateStatsFromBg();
    }
  });

  if (kReleaseMode) {
    await SentryFlutter.init((options) {
      options.dsn = SENTRY_URL;
    }, appRunner: () => runApp(ParentWidget()));
  } else {
    runApp(AudioHandlerInheritedWidget(audioHandler: _audioHandler, child: ParentWidget()));
  }
}

/// This Widget is the main application widget.
class ParentWidget extends StatefulWidget {
  static const String _title = 'Medito';

  @override
  _ParentWidgetState createState() => _ParentWidgetState();
}

class _ParentWidgetState extends State<ParentWidget>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: MeditoColors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarColor: MeditoColors.transparent),
    );

    // listened for app background/foreground events
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      urlPathStrategy: UrlPathStrategy.path,
      debugLogDiagnostics: true,
      routes: [
        GoRoute(
            path: HomePath,
            builder: (context, state) => HomeWrapperWidget(),
            routes: [
              _getSessionRoute(),
              _getArticleRoute(),
              _getDailyRoute(),
              GoRoute(
                path: 'app',
                pageBuilder: (context, state) =>
                    getCollectionMaterialPage(state),
              ),
              GoRoute(
                path: 'folder/:fid',
                routes: [
                  _getSessionRoute(),
                  GoRoute(
                    path: 'folder2/:f2id',
                    routes: [
                      _getSessionRoute(),
                      GoRoute(
                        path: 'folder3/:f3id',
                        pageBuilder: (context, state) =>
                            getFolderMaterialPage(state),
                        routes: [
                          _getSessionRoute(),
                        ],
                      ),
                    ],
                    pageBuilder: (context, state) =>
                        getFolderMaterialPage(state),
                  ),
                ],
                pageBuilder: (context, state) => getFolderMaterialPage(state),
              ),
            ]),
      ],
    );

    return MaterialApp.router(
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      theme: ThemeData(
          splashColor: MeditoColors.moonlight,
          canvasColor: MeditoColors.darkMoon,
          pageTransitionsTheme: PageTransitionsTheme(builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: SlideTransitionBuilder(),
          }),
          accentColor: MeditoColors.walterWhite,
          textTheme: meditoTextTheme(context)),
      title: ParentWidget._title,
    );
  }

  GoRoute _getDailyRoute() {
    return GoRoute(
              path: 'daily/:did',
              pageBuilder: (context, state) =>
                  getSessionOptionsDailyPage(state),
            );
  }

  GoRoute _getArticleRoute() {
    return GoRoute(
              path: 'article/:aid',
              pageBuilder: (context, state) => getArticleMaterialPAge(state),
            );
  }

  GoRoute _getSessionRoute() {
    return GoRoute(
      path: 'session/:sid',
      routes: [
        GoRoute(
          path: 'player',
          pageBuilder: (context, state) => getPlayerMaterialPage(state),
        )
      ],
      pageBuilder: (context, state) => getSessionOptionsMaterialPage(state),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // update session stats when app comes into foreground
      updateStatsFromBg();
    }
  }
}


class SlideTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    animation = CurvedAnimation(curve: Curves.easeInOutExpo, parent: animation);

    return SlideTransition(
      position: Tween(begin: Offset(1.0, 0.0), end: Offset(0.0, 0.0))
          .animate(animation),
      child: child,
    );
  }
}
