/// ═══════════════════════════════════════════════════════════════════════════
/// DFC STRIPE PAYMENT LINKS — Central config for all Stripe checkout URLs
/// ═══════════════════════════════════════════════════════════════════════════
///
/// These are Stripe Payment Links (hosted checkout pages).
/// Users click → Stripe handles the entire payment flow → done.
/// No SDK needed. Works on web, iOS, Android instantly.
///
/// NOTE: These are TEST MODE links. When going live, recreate products
/// in live mode and replace these URLs.
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:url_launcher/url_launcher.dart';

class DfcStripeLinks {
  DfcStripeLinks._();

  static const bool _useLiveLinks = bool.fromEnvironment(
    'STRIPE_USE_LIVE_LINKS',
  );

  // ── Stripe Dashboard ───────────────────────────────────────────────────
  static const String dashboardUrl =
      'https://dashboard.stripe.com/acct_1T6WevBSoM6ez8FY';

  // ═══════════════════════════════════════════════════════════════════════
  // SUBSCRIPTIONS — Recurring plans
  // ═══════════════════════════════════════════════════════════════════════

  /// Fighter Pro — A$4.99/month
  static const String _fighterProMonthlyTest =
      'https://buy.stripe.com/test_cNi3cxd4n8J91IW8fHdnW03';
  static const String _fighterProMonthlyLive = String.fromEnvironment(
    'STRIPE_LINK_FIGHTER_PRO_MONTHLY',
  );
  static String get fighterProMonthly =>
      _useLiveLinks && _fighterProMonthlyLive.isNotEmpty
      ? _fighterProMonthlyLive
      : _fighterProMonthlyTest;

  /// Fighter Pro — A$49.99/year (save $10 vs monthly · ~A$4.17/month)
  static const String _fighterProYearlyTest =
      'https://buy.stripe.com/test_28E4gB7K3e3tfzM3ZrdnW02';
  static const String _fighterProYearlyLive = String.fromEnvironment(
    'STRIPE_LINK_FIGHTER_PRO_YEARLY',
  );
  static String get fighterProYearly =>
      _useLiveLinks && _fighterProYearlyLive.isNotEmpty
      ? _fighterProYearlyLive
      : _fighterProYearlyTest;

  /// Coach & Mentor — A$7.99/month
  static const String _coachMentorMonthlyTest =
      'https://buy.stripe.com/test_3cI4gBd4naRhdrE67zdnW01';
  static const String _coachMentorMonthlyLive = String.fromEnvironment(
    'STRIPE_LINK_COACH_MENTOR_MONTHLY',
  );
  static String get coachMentorMonthly =>
      _useLiveLinks && _coachMentorMonthlyLive.isNotEmpty
      ? _coachMentorMonthlyLive
      : _coachMentorMonthlyTest;

  /// Coach & Mentor — A$79.99/year (save ~$16 vs monthly · ~A$6.67/month)
  static const String _coachMentorYearlyTest =
      'https://buy.stripe.com/test_fZucN7d4n3oPevI8fHdnW00';
  static const String _coachMentorYearlyLive = String.fromEnvironment(
    'STRIPE_LINK_COACH_MENTOR_YEARLY',
  );
  static String get coachMentorYearly =>
      _useLiveLinks && _coachMentorYearlyLive.isNotEmpty
      ? _coachMentorYearlyLive
      : _coachMentorYearlyTest;

  /// Promoter & Gym — A$14.99/month
  static const String _promoterGymMonthlyTest =
      'https://buy.stripe.com/test_3cI6oJd4ncZp5Zc53vdnW04';
  static const String _promoterGymMonthlyLive = String.fromEnvironment(
    'STRIPE_LINK_PROMOTER_GYM_MONTHLY',
  );
  static String get promoterGymMonthly =>
      _useLiveLinks && _promoterGymMonthlyLive.isNotEmpty
      ? _promoterGymMonthlyLive
      : _promoterGymMonthlyTest;

  /// Promoter & Gym — A$149.99/year (save ~$30 vs monthly · ~A$12.50/month)
  static const String _promoterGymYearlyTest =
      'https://buy.stripe.com/test_28E28td4n0cD2N0brTdnW05';
  static const String _promoterGymYearlyLive = String.fromEnvironment(
    'STRIPE_LINK_PROMOTER_GYM_YEARLY',
  );
  static String get promoterGymYearly =>
      _useLiveLinks && _promoterGymYearlyLive.isNotEmpty
      ? _promoterGymYearlyLive
      : _promoterGymYearlyTest;

  /// Supporter — A$2.99/month
  static const String _supporterMonthlyTest =
      'https://buy.stripe.com/test_3cIcN7e8rcZpgDQdA1dnW0i';
  static const String _supporterMonthlyLive = String.fromEnvironment(
    'STRIPE_LINK_SUPPORTER_MONTHLY',
  );
  static String get supporterMonthly =>
      _useLiveLinks && _supporterMonthlyLive.isNotEmpty
      ? _supporterMonthlyLive
      : _supporterMonthlyTest;

  // ═══════════════════════════════════════════════════════════════════════
  // EVENT TICKETS (one-time)
  // ═══════════════════════════════════════════════════════════════════════

  /// General Admission — A$79.99
  static const String ticketGeneral =
      'https://buy.stripe.com/test_3cIdRb8O7aRh5ZcanPdnW09';

  /// Ringside — A$199.99
  static const String ticketRingside =
      'https://buy.stripe.com/test_6oUeVf9Sbf7x1IW7bDdnW0b';

  /// VIP Floor — A$349.99
  static const String ticketVipFloor =
      'https://buy.stripe.com/test_9B68wR9SbgbB9bofI9dnW0f';

  /// VIP Suite — A$699.99
  static const String ticketVipSuite =
      'https://buy.stripe.com/test_6oUfZje8r5wX2N0dA1dnW0h';

  /// Backstage All-Access — A$1,499.99
  static const String ticketBackstage =
      'https://buy.stripe.com/test_fZu6oJggz1gH5ZceE5dnW0g';

  // ═══════════════════════════════════════════════════════════════════════
  // DONATIONS (one-time)
  // ═══════════════════════════════════════════════════════════════════════

  /// Donate A$5
  static const String donate5 =
      'https://buy.stripe.com/test_aFabJ37K38J9bjw9jLdnW0e';

  /// Donate A$10
  static const String donate10 =
      'https://buy.stripe.com/test_eVqdRbggz6B12N0cvXdnW0c';

  /// Donate A$25
  static const String donate25 =
      'https://buy.stripe.com/test_bJe14pfcvcZp3R4dA1dnW0d';

  /// Donate A$50
  static const String donate50 =
      'https://buy.stripe.com/test_28E4gB7K3e3tfzM3ZrdnW02';

  /// Donate A$100
  static const String donate100 =
      'https://buy.stripe.com/test_dRm4gBe8r5wX2N01RjdnW06';

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get subscription link by tier name and billing period
  static String? subscriptionLink(String tier, {bool yearly = false}) {
    switch (tier.toLowerCase()) {
      case 'fighter pro':
      case 'fighterpro':
      case 'pro':
        return yearly ? fighterProYearly : fighterProMonthly;
      case 'coach & mentor':
      case 'coachmentor':
      case 'coach':
        return yearly ? coachMentorYearly : coachMentorMonthly;
      case 'promoter & gym':
      case 'promotergym':
      case 'promoter':
      case 'promoter/gym':
      case 'promoter cmd':
        return yearly ? promoterGymYearly : promoterGymMonthly;
      case 'supporter':
        return supporterMonthly;
      default:
        return null;
    }
  }

  /// Get ticket link by tier
  static String ticketLink(String tier) {
    switch (tier.toLowerCase()) {
      case 'ringside':
        return ticketRingside;
      case 'vip floor':
      case 'vipfloor':
      case 'vip cageside':
        return ticketVipFloor;
      case 'vip suite':
      case 'vipsuite':
        return ticketVipSuite;
      case 'backstage':
      case 'backstage all-access':
      case 'dfc platinum':
      case 'platinum':
        return ticketBackstage;
      default:
        return ticketGeneral;
    }
  }

  /// Get donation link by amount
  static String donationLink(int amountDollars) {
    if (amountDollars <= 5) return donate5;
    if (amountDollars <= 10) return donate10;
    if (amountDollars <= 25) return donate25;
    if (amountDollars <= 50) return donate50;
    return donate100;
  }

  /// Open a Stripe payment link in the browser
  static Future<bool> openPaymentLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
