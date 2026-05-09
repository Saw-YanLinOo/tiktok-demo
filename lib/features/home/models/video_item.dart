class VideoItem {
  const VideoItem({
    required this.id,
    required this.creator,
    required this.initials,
    required this.caption,
    required this.videoUrl,
    required this.audioLabel,
  });

  final String id;
  final String creator;
  final String initials;
  final String caption;
  final String videoUrl;
  final String audioLabel;

  // Real CDN videos from the prototype's videos.json
  // Base: https://static.ybhospital.net/
  static const _base = 'https://static.ybhospital.net/';

  static List<VideoItem> get mockList => [
        VideoItem(
          id: 'v1',
          creator: '@night.walker',
          initials: 'N',
          caption: '测试片段 6，你们更喜欢白天还是夜景？',
          videoUrl: '${_base}test-video-6.mp4',
          audioLabel: 'clip 6 · original · clip 6',
        ),
        VideoItem(
          id: 'v2',
          creator: '@city.frames',
          initials: 'C',
          caption: '今天这条是 10，路过就顺手拍一下',
          videoUrl: '${_base}test-video-10.MP4',
          audioLabel: 'clip 10 · original · clip 10',
        ),
        VideoItem(
          id: 'v3',
          creator: '@slowmo.daily',
          initials: 'S',
          caption: 'test clip 9 · keep scrolling ✨',
          videoUrl: '${_base}test-video-9.MP4',
          audioLabel: 'clip 9 · original · clip 9',
        ),
        VideoItem(
          id: 'v4',
          creator: '@street.vibes',
          initials: 'V',
          caption: '第 8 条素材回放，氛围感拉满',
          videoUrl: '${_base}test-video-8.MP4',
          audioLabel: 'clip 8 · original · clip 8',
        ),
        VideoItem(
          id: 'v5',
          creator: '@light.chaser',
          initials: 'L',
          caption: 'test clip 7 · keep scrolling ✨',
          videoUrl: '${_base}test-video-7.MP4',
          audioLabel: 'clip 7 · original · clip 7',
        ),
        VideoItem(
          id: 'v6',
          creator: '@night.walker',
          initials: 'N',
          caption: '今天这条是 1，路过就顺手拍一下',
          videoUrl: '${_base}test-video-1.mp4',
          audioLabel: 'clip 1 · original · clip 1',
        ),
        VideoItem(
          id: 'v7',
          creator: '@city.frames',
          initials: 'C',
          caption: '测试片段 2，你们更喜欢白天还是夜景？',
          videoUrl: '${_base}test-video-2.mp4',
          audioLabel: 'clip 2 · original · clip 2',
        ),
        VideoItem(
          id: 'v8',
          creator: '@slowmo.daily',
          initials: 'S',
          caption: '第 3 条素材回放，氛围感拉满',
          videoUrl: '${_base}test-video-3.mp4',
          audioLabel: 'clip 3 · original · clip 3',
        ),
        VideoItem(
          id: 'v9',
          creator: '@street.vibes',
          initials: 'V',
          caption: 'test clip 4 · keep scrolling ✨',
          videoUrl: '${_base}test-video-4.mp4',
          audioLabel: 'clip 4 · original · clip 4',
        ),
      ];
}
