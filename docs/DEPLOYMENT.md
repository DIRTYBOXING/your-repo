# DataFightCentral Deployment Guide

## Android (Google Play Store)

1.  **Build the App Bundle:** Run `flutter build appbundle`.
2.  **Create a Google Play Developer Account:** If you don't have one, create one [here](https://play.google.com/apps/publish/signup/).
3.  **Create an App in Play Console:** Create a new app in your Play Console.
4.  **Fill in Store Listing:** Provide all the required information for your app's store listing.
5.  **Upload App Bundle:** Upload the app bundle you created in step 1.
6.  **Roll out to Production:** Follow the steps in the Play Console to roll out your app.

## iOS (App Store)

1.  **Build the iOS App:** Run `flutter build ios`.
2.  **Configure in Xcode:** Open the `ios/Runner.xcworkspace` file in Xcode and configure your app's settings.
3.  **Create an Apple Developer Account:** If you don't have one, create one [here](https://developer.apple.com/).
4.  **Archive and Upload:** Archive your app in Xcode and upload it to App Store Connect.
5.  **Submit for Review:** Fill in all the required metadata and submit your app for review.
