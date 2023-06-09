import 'package:flutter_dotenv/flutter_dotenv.dart';

class HTTPConstants {
  static String BASE_URL = dotenv.env['BASE_URL_STAGING']!;
  static String TEST_BASE_URL = dotenv.env['BASE_URL']!;
  static String INIT_TOKEN = dotenv.env['INIT_TOKEN']!;
  static String CONTENT_TOKEN = dotenv.env['CONTENT_TOKEN']!;
  static const String FOLDERS = 'folders';
  static const String SESSIONS = 'sessions';
  static const String BACKGROUND_SOUNDS = 'backgroundSounds';
}
