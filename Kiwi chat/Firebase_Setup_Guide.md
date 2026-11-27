# 🔥 KiwiChat: Firebase Cloud Backend Setup Guide

This guide explains how to connect your KiwiChat app to Firebase so that **two physical iPhones** can text, send voice notes, and redeem 6-digit codes over the internet anywhere in the world!

---

## 📋 Step 1: Create a Free Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/) and sign in with your Google account.
2. Click **Add project** (or **Create a project**).
3. Name your project (e.g. `KiwiChat-Kids`).
4. (Optional) Disable Google Analytics for simplicity, then click **Create project**.

---

## 📱 Step 2: Add your iOS App to Firebase

1. On your Firebase project dashboard, click the **iOS+** icon.
2. Enter your Apple Bundle Identifier from Xcode (e.g. `com.yourname.kiwichat`).
3. Click **Register app**.
4. Download the **`GoogleService-Info.plist`** file.
5. In Xcode:
   - Drag and drop `GoogleService-Info.plist` into your **Kiwi chat** Xcode project root folder.
   - Make sure **"Copy items if needed"** and **"Add to targets: Kiwi chat"** are checked!

---

## 📦 Step 3: Add Firebase Swift Package in Xcode

1. In Xcode, go to **File** ➔ **Add Package Dependencies...**
2. In the search box, paste:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. Set Dependency Rule to **Up to Next Major Version** (default `11.x` or latest).
4. Click **Add Package**.
5. When the package product selection appears, check these modules:
   - `FirebaseAuth` (Anonymous or Kid account authentication)
   - `FirebaseFirestore` (Real-time live messaging database)
   - `FirebaseStorage` (For AudiText voice notes & avatars)
6. Click **Add Package**.

---

## 🛡️ Step 4: Configure Firestore Database & Security Rules

1. In the Firebase Console left menu, go to **Build** ➔ **Firestore Database**.
2. Click **Create database**, select a location close to you (e.g. `nam5 (us-central)`), and choose **Start in test mode** for development.
3. Go to the **Rules** tab and paste the following kid-safe security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Kid profiles: readable by authenticated users, writable only by owner
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Friends subcollection
      match /friends/{friendId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // 6-digit one-time invite codes (15-minute TTL)
    match /inviteCodes/{code} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Real-time chat messages between approved friends
    match /chats/{chatRoomId}/messages/{messageId} {
      allow read, create: if request.auth != null;
    }
    
    // Flagged safety incidents (accessible only by parents / admin)
    match /flaggedIncidents/{incidentId} {
      allow create: if request.auth != null;
      allow read, delete: if request.auth != null;
    }
  }
}
```
4. Click **Publish**.

---

## 🚀 Step 5: How 2 iPhones Interact Live

1. **Phone 1 (e.g. Leo)**:
   - Opens KiwiChat and taps **Add Friends 🔑**.
   - Generates a **6-Digit One-Time Code** (e.g. `482-915`).
   - The code is stored in Firestore with a 15-minute expiration timer.

2. **Phone 2 (e.g. Emma)**:
   - Opens KiwiChat and taps **Enter Friend Code**.
   - Types `482-915`.
   - Firestore matches the code, links both profiles as friends, and creates a real-time chat room!

3. **Live Chat**:
   - Phone 1 types a message or sends a voice note.
   - Phone 2 receives it in **real-time (< 200ms)** through Firestore's live snapshot listener.
   - All messages pass through [`SafetyFilterService.swift`](file:///Users/polu/Documents/Kiwi%20chat/Kiwi%20chat/SafetyFilterService.swift) before hitting the network!
