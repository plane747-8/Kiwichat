# 🌐 How to Deploy KiwiChat Server to Render for Free (Worldwide Chat!)

This guide walks you through deploying your `kiwi_server.py` onto [Render.com](https://render.com) so friends can chat in real-time from anywhere in the world (e.g., Ohio to Japan, on 5G or Wi-Fi).

---

## ⏱️ Total Time: ~3 Minutes (100% Free)

### Step 1: Push your project to GitHub
If your project isn't on GitHub yet:
1. Open [GitHub](https://github.com/new) and create a new repository called `kiwichat`.
2. In VS Code or Terminal, run:
   ```bash
   git add .
   git commit -m "Add Render cloud server support"
   git remote add origin https://github.com/YOUR_USERNAME/kiwichat.git
   git branch -M main
   git push -u origin main
   ```

---

### Step 2: Deploy on Render
1. Go to [https://render.com](https://render.com) and sign up / log in (you can log in with GitHub).
2. Click **New +** ➔ **Web Service**.
3. Select **Build and deploy from a Git repository** and connect your `kiwichat` repo.
4. Fill in these simple fields:
   - **Name**: `kiwichat-server` (or whatever you prefer)
   - **Language**: `Python 3`
   - **Build Command**: *(leave empty or keep default)*
   - **Start Command**: `python3 'Kiwi chat/kiwi_server.py'`
   - **Instance Type**: **Free**
5. Click **Deploy Web Service**!

Render will build and start your server in about 60 seconds.

---

### Step 3: Get your Public URL & Put it in KiwiChat
1. Once deployed, Render will display your public URL at the top left of the dashboard:
   ```text
   https://kiwichat-server.onrender.com
   ```
2. Open **KiwiChat** on both phones.
3. In **Parental Controls ⚙️ ➔ Live 2-Phone Network 📡**:
   - Change Server Address to:
     ```text
     kiwichat-server.onrender.com
     ```
   - Tap **Connect Live Server**.
4. Both devices will now display `Live Connected 🟢`!

---

### 🎉 You're Live Worldwide!
- A kid in **Ohio** creates a 6-digit invite code (e.g., `492-108`).
- A kid in **Japan** enters `492-108`.
- Both phones connect in under 100ms, and messages fly across the globe in real time!
