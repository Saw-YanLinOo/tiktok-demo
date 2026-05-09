class LiveStream {
  const LiveStream({
    required this.id,
    required this.creator,
    required this.initials,
    required this.title,
    required this.viewerCount,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final String id;
  final String creator;
  final String initials;
  final String title;
  final String viewerCount;
  final int gradientStart; // Color hex
  final int gradientEnd;

  static List<LiveStream> get mockList => const [
        LiveStream(
          id: 'ls1',
          creator: '@xiaoyu_studio',
          initials: '小',
          title: '晚安直播间 🌙',
          viewerCount: '3.2k',
          gradientStart: 0xFF7A1A45,
          gradientEnd: 0xFF0D0510,
        ),
        LiveStream(
          id: 'ls2',
          creator: '@neon.diver',
          initials: 'N',
          title: 'midnight lofi pool',
          viewerCount: '842',
          gradientStart: 0xFF0A3535,
          gradientEnd: 0xFF071E1E,
        ),
        LiveStream(
          id: 'ls3',
          creator: '@ramen.king',
          initials: 'R',
          title: '拉面 day 5 现熬',
          viewerCount: '12.4k',
          gradientStart: 0xFF3D2A00,
          gradientEnd: 0xFF261A00,
        ),
        LiveStream(
          id: 'ls4',
          creator: '@city.frames',
          initials: 'C',
          title: 'city night walk',
          viewerCount: '1.1k',
          gradientStart: 0xFF0A3535,
          gradientEnd: 0xFF071E1E,
        ),
        LiveStream(
          id: 'ls5',
          creator: '@light.chaser',
          initials: 'L',
          title: 'golden hour ✨',
          viewerCount: '522',
          gradientStart: 0xFF3D1515,
          gradientEnd: 0xFF260C0C,
        ),
      ];
}
