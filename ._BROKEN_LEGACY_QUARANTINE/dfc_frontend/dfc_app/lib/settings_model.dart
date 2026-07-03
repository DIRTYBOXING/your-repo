class SettingsModel {
  final bool pushNotifications;
  final bool emailUpdates;
  final bool biometricLogin;
  final String subscriptionTier;
  final String paymentMethod;

  SettingsModel({
    this.pushNotifications = true,
    this.emailUpdates = false,
    this.biometricLogin = true,
    this.subscriptionTier = 'Pro Tier (Active)',
    this.paymentMethod = 'Visa ending in 4242',
  });

  SettingsModel copyWith({bool? pushNotifications, bool? emailUpdates, bool? biometricLogin}) {
    return SettingsModel(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailUpdates: emailUpdates ?? this.emailUpdates,
      biometricLogin: biometricLogin ?? this.biometricLogin,
      subscriptionTier: subscriptionTier,
      paymentMethod: paymentMethod,
    );
  }
}