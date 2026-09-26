# 📡 Offline Mesh Chat

A peer-to-peer chat app that works **without internet, WiFi, or cell towers** — using Bluetooth Low Energy mesh networking.

## ✨ Features
- 🔵 Works completely offline (airplane mode + Bluetooth)
- 📱 Auto-discovers nearby users
- 🔁 Multi-hop message relaying (messages pass through other phones)
- 💾 Local message history
- 🎨 Clean Material Design UI

## 🛠️ Tech Stack
- Flutter (cross-platform: Android + iOS)
- flutter_blue_plus (BLE)
- Provider (state)
- SharedPreferences (storage)

## 🚀 Setup
```bash
git clone https://github.com/roshangit botAI/offline-mesh-chat.git
cd offline-mesh-chat
flutter pub get
flutter run
