#!/bin/bash
# Run this script via cron or scheduler to keep DFC feeds fresh
cd "$(dirname "$0")/.."
#!/bin/bash
# scripts/auto_feed_cron.sh
# Run the intake service every 30 minutes

# Load environment variables (edit as needed or source from a .env file)
export DATABASE_URL="postgres://dfc:dfcpass@localhost:5432/dfc_audit"
export YOUTUBE_API_KEY="projects/your-secret" # Use Secret Manager in production

# Ensure logs directory exists
mkdir -p logs

# Change to project root
cd "$(dirname "$0")/.."

# Run the intake service and append output to log
npx ts-node src/feeds/intake.ts >> logs/auto_feed.log 2>&1

<!-- Facebook Pixel -->
<script>
  !function(f,b,e,v,n,t,s)
  {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
  n.callMethod.apply(n,arguments):n.queue.push(arguments)};
  if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
  n.queue=[];t=b.createElement(e);t.async=!0;
  t.src=v;s=b.getElementsByTagName(e)[0];
  s.parentNode.insertBefore(t,s)}(window, document,'script',
  'https://connect.facebook.net/en_US/fbevents.js');
  fbq('init', 'PIXEL_ID');
  fbq('track', 'PageView');
</script>
<noscript><img height="1" width="1" style="display:none"
  src="https://www.facebook.com/tr?id=PIXEL_ID&ev=PageView&noscript=1"
/></noscript>
<!-- End Facebook Pixel -->

navigator.serviceWorker.getRegistrations().then(regs => regs.forEach(r => r.unregister()));
location.reload(true);

firebase.auth().setPersistence(firebase.auth.Auth.Persistence.LOCAL)
  .then(() => console.log('persistence set to LOCAL'))
  .catch(e => console.error('persistence error', e));

console.log('currentUser', firebase.auth().currentUser);
firebase.auth().onAuthStateChanged(u => console.log('auth state changed', u));

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
[
  {
    "origin": ["https://www.datafightcentral.com","https://datafightcentral.web.app"],
    "method": ["GET","POST","PUT","HEAD"],
    "responseHeader": ["Content-Type","x-goog-resumable","Authorization"],
    "maxAgeSeconds": 3600
  }
]
# apply:
gsutil cors set cors.json gs://YOUR_BUCKET_NAME
