class VideoItem {
  const VideoItem({
    required this.id,
    required this.creator,
    required this.initials,
    required this.caption,
    required this.videoUrl,
    required this.audioLabel,
    this.size = 0,     // file size in bytes (0 = unknown until HEAD resolves)
    this.duration = 0, // duration in seconds (0 = unknown until controller inits)
  });

  final String id;
  final String creator;
  final String initials;
  final String caption;
  final String videoUrl;
  final String audioLabel;

  /// Actual file size in bytes. Used to sort smallest-first for preloading.
  final int size;

  /// Video duration in seconds.  0 until the player controller initialises.
  final int duration;

  static const _base = 'https://static.ybhospital.net/';

  static List<VideoItem> get mockList => [
        VideoItem(
          id: 'v1',
          creator: '@night.walker',
          initials: 'N',
          caption: '测试片段 6，你们更喜欢白天还是夜景？',
          videoUrl: '${_base}test-video-6.mp4',
          audioLabel: 'clip 6 · original · clip 6',
          size: 2_100_000,
          duration: 14,
        ),
        VideoItem(
          id: 'v2',
          creator: '@city.frames',
          initials: 'C',
          caption: '今天这条是 10，路过就顺手拍一下',
          videoUrl: '${_base}test-video-10.MP4',
          audioLabel: 'clip 10 · original · clip 10',
          size: 4_700_000,
          duration: 22,
        ),
        VideoItem(
          id: 'v3',
          creator: '@slowmo.daily',
          initials: 'S',
          caption: 'test clip 9 · keep scrolling ✨',
          videoUrl: '${_base}test-video-9.MP4',
          audioLabel: 'clip 9 · original · clip 9',
          size: 3_800_000,
          duration: 18,
        ),
        VideoItem(
          id: 'v4',
          creator: '@street.vibes',
          initials: 'V',
          caption: '第 8 条素材回放，氛围感拉满',
          videoUrl: '${_base}test-video-8.MP4',
          audioLabel: 'clip 8 · original · clip 8',
          size: 3_700_000,
          duration: 16,
        ),
        VideoItem(
          id: 'v5',
          creator: '@light.chaser',
          initials: 'L',
          caption: 'test clip 7 · keep scrolling ✨',
          videoUrl: '${_base}test-video-7.MP4',
          audioLabel: 'clip 7 · original · clip 7',
          size: 6_300_000,
          duration: 15,
        ),
        VideoItem(
          id: 'v6',
          creator: '@night.walker',
          initials: 'N',
          caption: '今天这条是 1，路过就顺手拍一下',
          videoUrl: '${_base}test-video-1.mp4',
          audioLabel: 'clip 1 · original · clip 1',
          size: 12_100_000,
          duration: 10,
        ),
        VideoItem(
          id: 'v7',
          creator: '@city.frames',
          initials: 'C',
          caption: '测试片段 2，你们更喜欢白天还是夜景？',
          videoUrl: '${_base}test-video-2.mp4',
          audioLabel: 'clip 2 · original · clip 2',
          size: 2_100_000,
          duration: 12,
        ),
        VideoItem(
          id: 'v8',
          creator: '@slowmo.daily',
          initials: 'S',
          caption: '第 3 条素材回放，氛围感拉满',
          videoUrl: '${_base}test-video-3.mp4',
          audioLabel: 'clip 3 · original · clip 3',
          size: 900_000,
          duration: 4,
        ),
        VideoItem(
          id: 'v9',
          creator: '@street.vibes',
          initials: 'V',
          caption: 'test clip 4 · keep scrolling ✨',
          videoUrl: '${_base}test-video-4.mp4',
          audioLabel: 'clip 4 · original · clip 4',
          size: 2_300_000,
          duration: 16,
        ),
        VideoItem(
          id: 'v10',
          creator: '@catbox.clips',
          initials: 'C',
          caption: 'vibes only 🔥',
          videoUrl: 'https://files.catbox.moe/3tcyw3.mp4',
          audioLabel: '3tcyw3 · original · 3t',
          size: 356_000,
          duration: 15,
        ),
        VideoItem(
          id: 'v11',
          creator: '@catbox.clips',
          initials: 'C',
          caption: 'keep scrolling ✨',
          videoUrl: 'https://files.catbox.moe/ibu6be.mp4',
          audioLabel: 'ibu6be · original · ib',
          size: 103_000,
          duration: 15,
        ),
      ];
}

