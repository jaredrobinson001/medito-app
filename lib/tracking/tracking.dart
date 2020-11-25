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
import 'package:Medito/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' as Foundation;

class Tracking {
  static const String SCREEN_LOADED = "screen_loaded";
  static const String FILE_TAPPED = "file_tapped";
  static const String CTA_TAPPED = "cta_tapped";
  static const String MAIN_CTA_TAPPED = "main_cta_tapped";
  static const String SECOND_CTA_TAPPED = "second_cta_tapped";
  static const String TILE = "tile";
  static const String TAP = "tap";

  static const String AUDIO_DOWNLOAD = "audio_download";
  static const String AUDIO_COMPLETED = "audio_completed";
  static const String AUDIO_COMPLETED_BUTTON_TAPPED =
      "audio_completed_button_tapped";

  static const String PLAYER_PAGE = "player_page";
  static const String PLAYER_END_PAGE = "player_end_page";
  static const String FOLDER_PAGE = "folder_page";
  static const String DONATION_PAGE_1 = "donation_page_1";
  static const String DONATION_PAGE_2 = "donation_page_2";
  static const String DONATION_PAGE_3 = "donation_page_3";
  static const String TEXT_PAGE = "text_page";
  static const String STREAK_PAGE = "streak_page";

  static const String TILE_TAPPED = "tile_tapped";
  static const String TRACKING_TAPPED = "tracking_tapped";
  static const String TEXT_TAPPED = "text_tapped";
  static const String FOLDER_TAPPED = "folder_tapped";
  static const String SESSION_TAPPED = "session_tapped";
  static const String PLAY_TAPPED = "play_tapped";

  static const String ACCEPT_TRACKING = "accept_tracking";
  static const String DENY_TRACKING = "deny_tracking";

  static const String HOME = "home_page";
  static FirebaseAnalytics _firebaseAnalytics;
  static FirebaseAnalyticsObserver _firebaseAnalyticsObserver;
  static DatabaseReference _dbRef;

  static const String _dbName = Foundation.kReleaseMode ? 'donations' : 'test';

  static Future<void> initialiseTracker(FirebaseApp app) async {
    _firebaseAnalytics = FirebaseAnalytics();
    _firebaseAnalyticsObserver =
        FirebaseAnalyticsObserver(analytics: _firebaseAnalytics);

    //dummy event
    _firebaseAnalytics.logEvent(
      name: "tracker_initialized",
      parameters: {},
    ).then((value) => print('tracking initialized'));

    final FirebaseDatabase database = FirebaseDatabase(app: app);

    _dbRef = database.reference().child(_dbName);
  }

  static FirebaseAnalyticsObserver getObserver() => _firebaseAnalyticsObserver;

  static void changeScreenName(String screenName) {
    _firebaseAnalytics.setCurrentScreen(screenName: screenName);
  }

  // like "LoginWidget", "Login button", "Clicked"
  static Future<void> trackEvent(
      String eventName, String action, String destination,
      {Map<String, String> map}) async {
    var accepted = await isTrackingAccepted();

    if (Foundation.kReleaseMode && accepted) {
      //only track in release mode, not debug

      Map<String, String> defaultMap = {
        "action": action.clean(),
        "destination": destination.clean(),
      };
      if (map != null) defaultMap.addAll(map);

      _firebaseAnalytics.logEvent(
        name: eventName.clean(),
        parameters: defaultMap,
      );

      print("Event logged: $eventName");
    }
  }

  static void enableAnalytics(bool enable) {
    _firebaseAnalytics.setAnalyticsCollectionEnabled(enable);
  }

  static void trackDonation(String recordName, Map<String, dynamic> map) {
    _dbRef.child(recordName).set(map);
  }

  static Future<void> trackTrackingAnswered(bool track) async {
    await Tracking.trackEvent(
        Tracking.TRACKING_TAPPED, Tracking.ACCEPT_TRACKING, "");
  }
}

extension on String {
  clean() {
    var str = this.replaceAll('/', '_').replaceAll('-', '_');

    if (str.isNotEmpty && !str.startsWith(new RegExp(r'[A-Za-z]'))) {
      str.replaceRange(0, 1, "");
    }

    return str;
  }
}
