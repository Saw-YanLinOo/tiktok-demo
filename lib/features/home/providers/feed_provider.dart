import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_item.dart';

/// The full list of videos — in production this would be fetched from an API
final feedProvider = Provider<List<VideoItem>>((ref) => VideoItem.mockList);

/// Which page is currently visible
final currentPageIndexProvider = StateProvider<int>((ref) => 0);
