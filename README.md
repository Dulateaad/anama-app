# 🌱 Anama — Emotional Safety for Teens

<p align="center">
  <img src="assets/logo.png" alt="Anama Logo" width="120"/>
</p>

<p align="center">
  <strong>A mental health monitoring app that helps parents understand their teenagers better</strong>
</p>

<p align="center">
  <a href="https://anama-app.web.app">🌐 Live Demo</a> •
  <a href="#features">✨ Features</a> •
  <a href="#installation">📦 Installation</a> •
  <a href="#tech-stack">🛠 Tech Stack</a>
</p>

---

## 📖 About

**Anama** is a mobile and web application designed to support the emotional well-being of teenagers (13-17 years old). The app creates a safe space for teens to express their feelings while providing parents with AI-powered insights — without compromising the teen's privacy.

### 🎯 Key Concept
- **Teens** answer daily questions ("Daily Confession") and take clinical tests (PHQ-9, GAD-7, Traffic Light)
- **AI (Gemini)** analyzes responses anonymously and determines risk level (🟢 Green / 🟡 Yellow / 🔴 Red)
- **Parents** receive insights and recommendations — not the actual answers
- **Psychologists** can connect with users through in-app chat

---

## ✨ Features

### For Teenagers 👦👧
- 📝 **Daily Confession** — 7 questions about mood, relationships, and goals
- 🧪 **Clinical Tests**:
  - **PHQ-9** — Depression screening (9 questions)
  - **GAD-7** — Anxiety screening (7 questions)  
  - **Traffic Light** — Emotional state assessment for ages 13-17
- 🆘 **SOS Button** — Quick access to crisis hotlines (150, 111)
- 💬 **Chat with Psychologists** — Anonymous consultations
- 🎮 **"Geniuses in Risk Zone"** — Motivational cards showing famous people who overcame struggles

### For Parents 👨‍👩‍👧
- 📊 **Soul Analytics** — AI-generated insights about child's emotional state
- 🎯 **Serve & Return Tasks** — Evidence-based interaction exercises
- 📈 **Risk Level History** — Track emotional trends over time
- 🔗 **Account Linking** — Connect with teen using a 6-digit code
- 🔔 **Notifications** — Alerts when risk level changes

### For Psychologists 🧠
- 👥 **Client Management** — View assigned clients
- 💬 **Secure Chat** — Communicate with teens/parents
- 📋 **Test Results** — Access clinical assessment data

---

## 🌍 Localization

The app supports **3 languages**:

| Language | Code | Status |
|----------|------|--------|
| 🇺🇸 English | `en` | ✅ Full |
| 🇷🇺 Russian | `ru` | ✅ Full |
| 🇰🇿 Kazakh | `kk` | ✅ Full |

All clinical tests (PHQ-9, GAD-7, Traffic Light) and survey questions are fully translated.

---

## ♿ Accessibility

Anama follows **WCAG 2.1 AA** guidelines:

- ✅ **Screen Reader Support** — Full `Semantics` implementation
- ✅ **Color Contrast** — Automatic 4.5:1 contrast ratio enforcement
- ✅ **Large Touch Targets** — Minimum 48x48dp for all interactive elements
- ✅ **Scalable Fonts** — 16-20px base sizes
- ✅ **Accessible Widgets** — Custom `AccessibleText`, `AccessibleButton`, `AccessibleCard`

---

## 🛠 Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.38+ |
| **Language** | Dart 3.10+ |
| **Backend** | Firebase (Firestore, Auth, Functions, Hosting) |
| **AI** | Google Gemini API |
| **State Management** | Provider |
| **Navigation** | go_router |
| **Notifications** | Firebase Cloud Messaging |

---

## 📦 Installation

### Prerequisites
- Flutter SDK 3.38+
- Firebase CLI
- Node.js 18+ (for Cloud Functions)

### Steps

1. **Clone the repository**
```bash
git clone https://github.com/anamakz/anamaapp.git
cd anamaapp
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (select existing project)
firebase use anama-app
```

4. **Add Firebase config files**
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

5. **Set up environment variables**
Create `.env` file in project root:
```
GEMINI_API_KEY=your_gemini_api_key
```

6. **Run the app**
```bash
# Web
flutter run -d chrome

# iOS
flutter run -d ios

# Android
flutter run -d android
```

---

## 🚀 Deployment

### Web (Firebase Hosting)
```bash
flutter build web --release
firebase deploy --only hosting
```

### Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

---

## 📁 Project Structure

```
lib/
├── l10n/                  # Localization
│   └── app_localizations.dart
├── models/                # Data models
│   ├── user_model.dart
│   ├── phq9_question.dart
│   ├── gad7_question.dart
│   ├── traffic_light_question.dart
│   └── question.dart
├── screens/               # UI screens
│   ├── auth/              # Login, Register, Password Reset
│   ├── teen/              # Teen home, Tests, Survey
│   ├── parent/            # Parent dashboard
│   ├── psychologists/     # Psychologist interface
│   └── settings/          # Language, Feedback
├── services/              # Business logic
│   ├── auth_service.dart
│   ├── gemini_service.dart
│   ├── survey_service.dart
│   └── clinical_test_service.dart
├── widgets/               # Reusable components
│   ├── accessible_text.dart
│   ├── accessible_card.dart
│   └── accessible_scaffold.dart
└── main.dart              # App entry point

functions/                 # Firebase Cloud Functions
├── index.js
└── package.json
```

---

## 🔐 Security & Privacy

- 🔒 **Anonymous Analysis** — AI sees patterns, not personal data
- 🔐 **Firebase Security Rules** — Role-based access control
- 🛡️ **No Raw Data to Parents** — Only risk levels and recommendations
- 📧 **Parental Consent** — OTP verification for teen registration

---

## 📊 Clinical Tests

### PHQ-9 (Patient Health Questionnaire-9)
Standard depression screening tool. Scores:
- 0-4: Minimal
- 5-9: Mild
- 10-14: Moderate
- 15-19: Moderately Severe
- 20-27: Severe

### GAD-7 (Generalized Anxiety Disorder-7)
Anxiety assessment scale. Scores:
- 0-4: Minimal
- 5-9: Mild
- 10-14: Moderate
- 15-21: Severe

### Traffic Light Test (13-17 years)
Custom assessment based on PHQ-9, GAD-7, and Yale/Harvard methodologies:
- **Block A**: Energy & Meaning
- **Block B**: Anxiety & Intrusive Thoughts
- **Block C**: Social Status & Future

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

- **Crisis Hotline (Kazakhstan)**: 150 (free, anonymous, 24/7)
- **Emergency Psychological Help**: 111
- **Online Chat**: [pomoschryadom.kz](https://pomoschryadom.kz)

---

<p align="center">
  Made with ❤️ for teens and families
</p>
