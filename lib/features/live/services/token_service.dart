import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../../../config/env.dart';
import '../models/room_config.dart';

/// Generates a LiveKit access token on-device using the API key + secret from .env.
///
/// ⚠️  In production, token generation must happen server-side.
///      This approach is acceptable for a demo only.
class TokenService {
  TokenService._();

  static String generate(RoomConfig config) {
    final jwt = JWT(
      {
        'video': {
          'room': config.roomName,
          'roomJoin': true,
          'canPublish': config.isHost,
          'canSubscribe': true,
          'canPublishData': true,
        },
      },
      issuer: Env.livekitApiKey,
      subject: config.identity,
    );

    return jwt.sign(
      SecretKey(Env.livekitApiSecret),
      expiresIn: const Duration(hours: 6),
    );
  }
}
