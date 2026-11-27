# 🥝 KiwiChat Custom Real-Time Server Guide

We built our own custom WebSocket networking backend in pure Python 3 with **zero 3rd-party dependencies or external SDKs**.

---

## 🚀 How to Run the Server on Your Mac (1 Command!)

Open **Terminal** on your Mac, navigate to the folder, and run:

```bash
cd "/Users/polu/Documents/Kiwi chat/Kiwi chat"
python3 kiwi_server.py
```

You'll see:
```text
============================================================
🥝  KiwiChat Custom Real-Time WebSocket Server
📡  Listening on all interfaces port 8080
📲  Both iPhones can connect to: ws://192.168.254.90:8080
============================================================
```

---

## 📱 How to Connect Both iPhones

### 1. Make sure both iPhones are on the same Wi-Fi network as your Mac.
Your Mac's local IP is: **`192.168.254.90`** (Port: **`8080`**).

### 2. Open KiwiChat on Phone 1 & Phone 2
- The app automatically connects to `192.168.254.90:8080` on launch!
- You can check the status in **Parental Controls ⚙️ ➔ Live 2-Phone Network 📡**:
  - `Live Connected 🟢`

---

## 🔑 How to Pair the 2 Phones Live

1. **On Phone 1 (e.g. Leo)**:
   - Tap **Add Friends 🔑** (or the `+` button in Chats).
   - Tap **Create 6-Digit Invite Code**.
   - A 6-digit code will appear (e.g. `739-104`).
   - The code is broadcast directly to your Mac server!

2. **On Phone 2 (e.g. Emma)**:
   - Tap **Add Friends 🔑 ➔ Enter Friend Code**.
   - Type `739104` and tap **Connect Friend**.

3. **Live Magic Happens**:
   - Both phones will vibrate and add each other to their friends list in under 50 milliseconds!
   - You can now send live text messages, waveforms voice notes, stickers, and start video/audio calls across the air! 🎉
