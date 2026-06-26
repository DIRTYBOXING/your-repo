/// Data Fight Central - Platform Information
///
/// OWNERSHIP & COPYRIGHT
/// Copyright (c) 2024-2026 Dirtyboxer Pty Ltd
/// All rights reserved.
///
/// This software and associated documentation files (the "Software") are
/// the proprietary property of Dirtyboxer Pty Ltd and its creator/developer.
///
/// Unauthorized copying, modification, distribution, or use of this Software
/// is strictly prohibited and may result in legal action.
///
/// CREATOR & DEVELOPER: [Your Legal Name]
/// CREATED: 2024
/// PLATFORM: Data Fight Central (DFC)
///
/// LICENSE: See LICENSE file for full terms
/// TERMS: See docs/TERMS_OF_SERVICE.md
/// PRIVACY: See docs/PRIVACY_POLICY.md
library;

class PlatformInfo {
  // Platform identification
  static const String name = 'Data Fight Central';
  static const String shortName = 'DFC';
  static const String legalEntity = 'Dirtyboxer Pty Ltd';
  static const String version = '1.0.0';

  // Copyright & ownership
  static const String copyrightYear = '2024-2026';
  static const String copyrightHolder = 'Dirtyboxer Pty Ltd';
  static const String creator = '[Your Legal Name]'; // FILL IN YOUR NAME

  // Legal notices
  static const String copyrightNotice =
      '© $copyrightYear $copyrightHolder. All rights reserved.';

  static const String ownershipNotice =
      'Data Fight Central is the exclusive property of $copyrightHolder '
      'and its creator/developer.';

  static const String trademarkNotice =
      'Data Fight Central™ and DFC™ are trademarks of $copyrightHolder.';

  // Liability disclaimer
  static const String disclaimer =
      'Data Fight Central provides information and communication services. '
      'We are not responsible for accuracy of user content, fight outcomes, '
      'injuries, or transactions between users. Use at your own risk.';

  // Contact information
  static const String infoEmail = 'info@datafightcentral.com';
  static const String helloEmail = 'hello@datafightcentral.com';
  static const String accountsEmail = 'accounts@datafightcentral.com';
  static const String supportEmail = 'support@datafightcentral.com';
  static const String legalEmail = 'legal@datafightcentral.com';
  static const String website = 'https://datafightcentral.com';

  // Social media pages — all 8 platforms
  static const String facebookPage =
      'https://www.facebook.com/datafightcentral';
  static const String instagramPage =
      'https://www.instagram.com/datafightcentral';
  static const String tiktokPage = 'https://www.tiktok.com/@datafightcentral';
  static const String youtubePage = 'https://www.youtube.com/@datafightcentral';
  static const String xPage = 'https://x.com/datafightcentral';
  static const String whatsappChannel = 'https://whatsapp.com/channel/dfc';
  static const String linkedinPage =
      'https://www.linkedin.com/company/datafightcentral';
  static const String snapchatPage =
      'https://www.snapchat.com/add/datafightcentral';

  // Community values — the DFC ecosystem promise
  static const String communityMission =
      'Fighters, promoters, gyms, and fans connect through a trusted platform for '
      'content, community, and commerce. DFC brings social media and PPV together '
      'for professional combat sports worldwide.';

  static const List<String> communityValues = [
    'Respect every fighter — no keyboard warriors, no degrading athletes',
    'Promote athlete health, safety, and long-term wellbeing',
    'Fans connect with fighters directly — real relationships, not parasocial noise',
    'Fighters connect with fans — build your brand with dignity and purpose',
    'Zero tolerance for bullying, defamation, or putting down athletes',
    'Build sustainable careers through professional tools and fair visibility',
    'We create a healthier ecosystem — combat sports as a force for good',
    'Every interaction builds community — no toxicity, only growth',
  ];

  // Services description
  static const String servicesDescription =
      'Live event production; streaming and PPV; online marketplace; branded merchandise.';

  // Legal document URLs
  static const String termsUrl = 'https://datafightcentral.com/terms';
  static const String privacyUrl = 'https://datafightcentral.com/privacy';
  static const String guidelinesUrl = 'https://datafightcentral.com/guidelines';

  // App store information
  static const String packageName = 'com.dirtyboxing.datafightcentral';
  static const String appleId = 'TBD'; // Fill in when published
  static const String playStoreId = 'TBD'; // Fill in when published
}

/// Display copyright notice in app footer
String getCopyrightNotice() {
  return PlatformInfo.copyrightNotice;
}

/// Display full legal notice
String getFullLegalNotice() {
  return '''
${PlatformInfo.copyrightNotice}

${PlatformInfo.ownershipNotice}

${PlatformInfo.trademarkNotice}

${PlatformInfo.disclaimer}

For Terms of Service, visit: ${PlatformInfo.termsUrl}
For Privacy Policy, visit: ${PlatformInfo.privacyUrl}

Created by ${PlatformInfo.creator}
''';
}
