import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static String get livekitUrl =>
      dotenv.env['LIVEKIT_URL'] ?? (throw Exception('LIVEKIT_URL not set in .env'));

  static String get livekitApiKey =>
      dotenv.env['LIVEKIT_API_KEY'] ?? (throw Exception('LIVEKIT_API_KEY not set in .env'));

  static String get livekitApiSecret =>
      dotenv.env['LIVEKIT_API_SECRET'] ?? (throw Exception('LIVEKIT_API_SECRET not set in .env'));
}
