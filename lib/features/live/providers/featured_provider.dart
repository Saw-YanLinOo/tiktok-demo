import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/live_stream.dart';

/// Featured live streams list — mock data from prototype
final featuredStreamsProvider = Provider<List<LiveStream>>(
  (ref) => LiveStream.mockList,
);
