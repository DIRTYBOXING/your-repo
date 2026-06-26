# DFC Launch Cheat Sheet

## Daily: Press F5

- Select **"DFC Web Sandbox (F5 this one)"** in the dropdown at the top of VS Code
- Chrome opens, app loads, done
- Stop: **Shift+F5** or close Chrome

## When Stuck: Clean

```
flutter clean
flutter pub get
```

This wipes old builds and re-downloads everything — fresh start.

## Launch Configs (dropdown next to the green play button)

| Config                            | When to use                                                |
| --------------------------------- | ---------------------------------------------------------- |
| **DFC Web Sandbox (F5 this one)** | Safe local repair lane — demo shell plus Firebase emulator |
| **DFC Web Live**                  | Real Google login, real feed/content, real backend checks  |
| **DFC Windows Desktop**           | Run as a Windows desktop app                               |
| **DFC Web Profile (find lag)**    | App feels slow, want performance data                      |
| **DFC Web Release Preview**       | See exactly what users see after deploy                    |

## Build for Deployment

1. Press **Ctrl+Shift+P**
2. Type **"Run Task"** and select it
3. Choose **"Flutter: Build Web Sandbox"** for local sandbox output or **"Flutter: Build Web Live"** for the real lane
4. Output goes to `build/web/` — that's what you upload

## What the Modes Mean

- **Debug** = for building/testing (hot reload, full error messages)
- **Profile** = for finding lag/slowness
- **Release** = what real users get (fast, optimized, no debug info)

## API Keys

- All stored in your `.env` file — loaded automatically
- You never need to type them into commands

## Lane Meanings

- **Sandbox** = `WEB_DEMO_MODE=true` and `USE_FIREBASE_EMULATOR=true`. Safe local sandbox with seeded content.
- **Live** = `WEB_DEMO_MODE=false` and `USE_FIREBASE_EMULATOR=false`. Real auth, real backend, real content lane.
- **Avoid** = demo without emulator. The scripts now block this unless you explicitly opt in.
