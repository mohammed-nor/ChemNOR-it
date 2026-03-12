<div align="center">

<img src="images/app_icon.png" alt="ChemNOR Logo" width="120" height="120" style="border-radius: 24px;" />

# ⚗️ ChemNOR

### *Your Intelligent Chemistry Assistant, Powered by AI*

[![Flutter](https://img.shields.io/badge/Flutter-5.0.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows-blueviolet?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![pub.dev](https://img.shields.io/badge/pub.dev-chem__nor-orange?style=for-the-badge&logo=dart)](https://pub.dev/packages/chem_nor)

> 🔬 **ChemNOR** is a cross-platform Flutter application that brings the power of AI directly into the world of chemistry. Search compounds, analyze structures, and chat with an AI chemist — all in one sleek interface.

</div>

---

<!-- ## 📸 Screenshots

<div align="center">

| Home / Search | Compound Details |
|:---:|:---:|
| <img src="images/1.png" width="260"/> | <img src="images/1.JPG" width="260"/> |

</div>

--- -->

## ✨ Features

| Feature | Description |
|---|---|
| 🔍 **Compound Search** | Search chemical compounds by name or formula using natural language. Get detailed properties and PubChem images instantly. |
| 🤖 **AI Chat** | Chat with an AI assistant about any compound. Context-aware answers powered by the ChemNOR and Gemini APIs. |
| 🧪 **Chemistry Tools** | Use chemistry-specific tools like the `chemist` function for deeper structural and property analysis. |
| 📜 **History** | Save and revisit AI responses locally using **Hive**. Long-press to copy or delete entries. |
| ⚙️ **Settings** | Configure API keys, font size, and global preferences — all persisted across sessions. |
| 🎨 **Modern UI** | Stylish bottom navigation, Markdown rendering, math formula support, and a fully responsive layout. |

---

## 🚀 Getting Started

### 🛠 Prerequisites

Make sure you have the following installed before you begin:

- ✅ [Flutter SDK](https://docs.flutter.dev/get-started/install) *(stable channel recommended)*
- ✅ Dart `^3.x`
- ✅ A valid **ChemNOR API key** and **Gemini API key**

### 📦 Installation

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/chemnor_it.git
cd chemnor_it

# 2. Install all dependencies
flutter pub get

# 3. Set up your environment variables
#    Create a .env file in the root directory:
#    CHEMNOR_API_KEY=your_chemnor_key
#    GEMINI_API_KEY=your_gemini_key

# 4. Run the app
flutter run
```

> 💡 **Tip:** Use `flutter run -d windows` to launch on desktop, or connect a device/emulator for mobile.

---

## 📖 Usage

### 🔍 Searching for Compounds
Enter a chemical name (e.g., *"caffeine"*) or formula (e.g., *"C8H10N4O2"*) in the search bar. Tap a result to explore full compound details including structure, molecular weight, and more.

### 💬 Chatting with AI
Navigate to the **AI Chat** tab and start a conversation about any compound. The AI uses compound context for precise, chemistry-aware responses.

### 🧪 Using Chemistry Tools
From the compound details page, tap the **Chemist** action to run deeper analysis using the built-in chemistry tools.

### 📜 Managing History
View saved AI responses in the **History** tab. Long-press any item to get options to **copy** or **delete** it.

### ⚙️ Adjusting Settings
Open the **Settings** tab to manage your API keys, change font size, and tweak app preferences.

---

## 🏗️ Project Structure

```
chemnor_it/
├── lib/                    # Main Dart source code
│   ├── main.dart           # Entry point
│   ├── screens/            # UI screens (Search, Chat, History, Settings)
│   ├── models/             # Data models
│   ├── providers/          # State management (Provider)
│   └── widgets/            # Reusable UI components
├── images/                 # App assets & screenshots
├── android/                # Android platform files
├── ios/                    # iOS platform files
├── windows/                # Windows platform files
├── pubspec.yaml            # Dependencies & metadata
└── README.md
```

---

## 📚 Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| [`chem_nor`](https://pub.dev/packages/chem_nor) | `^0.5.0` | Core chemistry API client |
| [`hive`](https://pub.dev/packages/hive) | `^2.2.1` | Local data persistence |
| [`gpt_markdown`](https://pub.dev/packages/gpt_markdown) | `^1.1.2` | Markdown & math rendering |
| [`url_launcher`](https://pub.dev/packages/url_launcher) | `^6.3.1` | External link handling |

---

## 🐛 Troubleshooting

<details>
<summary><b>🔴 App crashes on startup</b></summary>

- Ensure all dependencies are installed by running `flutter pub get`.
- Verify your `.env` file exists and contains valid API keys.
- Try running `flutter clean && flutter pub get` to reset the build.

</details>

<details>
<summary><b>🟡 API-related errors or no results</b></summary>

- Double-check your **ChemNOR API key** and **Gemini API key** in the Settings tab.
- Ensure you have an active internet connection.
- Check if the [ChemNOR API](https://pub.dev/packages/chem_nor) service is operational.

</details>

<details>
<summary><b>🔵 Build issues on Windows / iOS</b></summary>

- Consult the official [Flutter documentation](https://docs.flutter.dev/) for platform-specific setup guides.
- Check the [GitHub Issues](https://github.com/yourusername/chemnor_it/issues) page for community solutions.

</details>

---

## 🤝 Contributing

Contributions are always welcome! 🙌

```bash
# 1. Fork this repository

# 2. Create your feature branch
git checkout -b feature/amazing-feature

# 3. Commit your changes
git commit -m "✨ Add amazing feature"

# 4. Push to the branch
git push origin feature/amazing-feature

# 5. Open a Pull Request
```

Please make sure to update tests as appropriate and follow the existing code style.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for full details.

```
MIT License © 2024 ChemNOR Contributors
```

---

## 🙏 Acknowledgments

- 🌐 Powered by the **ChemNOR** and **Gemini** APIs for cutting-edge AI chemistry capabilities.
- 💙 Built with **Flutter** for a smooth, cross-platform experience.
- 📊 Compound data sourced from **PubChem** — the world's largest chemistry database.
- 🧠 Inspired by the need to make professional chemistry tools accessible to everyone.

---

<div align="center">

**Made with ❤️ and ⚗️ by the ChemNOR Team**

[![GitHub](https://img.shields.io/badge/GitHub-ChemNOR-181717?style=for-the-badge&logo=github)](https://github.com/yourusername/chemnor_it)

*⭐ Star this repo if you find it useful!*

</div>
