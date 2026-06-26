class SocialTemplateSize {
  final String id;
  final String platform;
  final String contentType;
  final int width;
  final int height;
  final String notes;
  final String? safeZone;

  const SocialTemplateSize({
    required this.id,
    required this.platform,
    required this.contentType,
    required this.width,
    required this.height,
    required this.notes,
    this.safeZone,
  });

  double get aspectRatio => width / height;

  String get dimensionsLabel => '$width×$height';

  String get placeholderUrl => 'assets/dfc_backgrounds/new_dfc_image_1.png';
}

class SocialMediaTemplateSizes {
  const SocialMediaTemplateSizes._();

  static const instagramPostSquare = SocialTemplateSize(
    id: 'instagram_post_square',
    platform: 'Instagram',
    contentType: 'Post (Square)',
    width: 1080,
    height: 1080,
    notes: 'Keep text within 960×960',
    safeZone: '960×960',
  );

  static const instagramPostPortrait = SocialTemplateSize(
    id: 'instagram_post_portrait',
    platform: 'Instagram',
    contentType: 'Post (Portrait)',
    width: 1080,
    height: 1350,
    notes: 'Tallest allowed',
  );

  static const instagramStoryReel = SocialTemplateSize(
    id: 'instagram_story_reel',
    platform: 'Instagram',
    contentType: 'Story / Reel',
    width: 1080,
    height: 1920,
    notes: 'Keep text in center 1080×1420',
    safeZone: '1080×1420',
  );

  static const facebookFeedImage = SocialTemplateSize(
    id: 'facebook_feed_image',
    platform: 'Facebook',
    contentType: 'Feed Image',
    width: 1200,
    height: 630,
    notes: 'Horizontal safe zone',
  );

  static const facebookStory = SocialTemplateSize(
    id: 'facebook_story',
    platform: 'Facebook',
    contentType: 'Story',
    width: 1080,
    height: 1920,
    notes: 'Same as Instagram',
  );

  static const facebookCoverPhoto = SocialTemplateSize(
    id: 'facebook_cover_photo',
    platform: 'Facebook',
    contentType: 'Cover Photo (Page)',
    width: 820,
    height: 360,
    notes: 'Safe zone: 640×312',
    safeZone: '640×312',
  );

  static const xPostLandscape = SocialTemplateSize(
    id: 'x_post_landscape',
    platform: 'X (Twitter)',
    contentType: 'Post Image (Landscape)',
    width: 1600,
    height: 900,
    notes: 'Min width 600px',
  );

  static const xProfileHeader = SocialTemplateSize(
    id: 'x_profile_header',
    platform: 'X (Twitter)',
    contentType: 'Profile Header',
    width: 1500,
    height: 500,
    notes: 'Keep text centered',
  );

  static const linkedInPostImage = SocialTemplateSize(
    id: 'linkedin_post_image',
    platform: 'LinkedIn',
    contentType: 'Post Image',
    width: 1200,
    height: 627,
    notes: 'Works for link previews',
  );

  static const linkedInProfileBackground = SocialTemplateSize(
    id: 'linkedin_profile_background',
    platform: 'LinkedIn',
    contentType: 'Profile Background',
    width: 1584,
    height: 396,
    notes: 'Safe zone center',
  );

  static const tiktokVideoStory = SocialTemplateSize(
    id: 'tiktok_video_story',
    platform: 'TikTok',
    contentType: 'Video / Story',
    width: 1080,
    height: 1920,
    notes: 'Keep captions above bottom 150px',
  );

  static const youtubeThumbnail = SocialTemplateSize(
    id: 'youtube_thumbnail',
    platform: 'YouTube',
    contentType: 'Thumbnail',
    width: 1280,
    height: 720,
    notes: 'Min width 640px',
  );

  static const youtubeChannelBanner = SocialTemplateSize(
    id: 'youtube_channel_banner',
    platform: 'YouTube',
    contentType: 'Channel Banner',
    width: 2560,
    height: 1440,
    notes: 'Safe zone: 1546×423',
    safeZone: '1546×423',
  );

  static const pinterestStandardPin = SocialTemplateSize(
    id: 'pinterest_standard_pin',
    platform: 'Pinterest',
    contentType: 'Standard Pin',
    width: 1000,
    height: 1500,
    notes: 'Vertical format',
  );

  static const List<SocialTemplateSize> all = [
    instagramPostSquare,
    instagramPostPortrait,
    instagramStoryReel,
    facebookFeedImage,
    facebookStory,
    facebookCoverPhoto,
    xPostLandscape,
    xProfileHeader,
    linkedInPostImage,
    linkedInProfileBackground,
    tiktokVideoStory,
    youtubeThumbnail,
    youtubeChannelBanner,
    pinterestStandardPin,
  ];
}
