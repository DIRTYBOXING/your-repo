dependencies:
video_player: ^ 2.5.0
cloud_functions: ^ 4.0.0
firebase_auth: ^ 4.0.0
intl: ^ 0.18.0
flutter_stripe: ^ 9.0.0
url_launcher: ^ 6.1.10
fl_chart: ^ 0.55.2
http: ^ 1.1.0

// Problem
var controller;

// Fix
late final MyController controller;

// Or if nullable
MyController ? controller;
