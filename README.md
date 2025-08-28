# ChemNOR It!

ChemNOR is a Flutter application that serves as an intelligent chemistry assistant. It leverages AI (via ChemNOR and ChemPUB APIs) to help users search for, analyze, and chat about chemical compounds. The app features a modern UI, persistent history, and chemistry-specific tools.

## Features

- **Compound Search:**  
  Search for chemical compounds using natural language. Results include detailed properties and PubChem images.

- **AI Chat:**  
  Chat with an AI assistant about any compound. The chat uses compound context for more relevant answers.

- **Chemistry Actions:**  
  Use chemistry-specific tools (e.g., the "chemist" function) for deeper analysis of compounds.

- **History:**  
  Save and review AI responses. Long-press to copy messages or delete them. All history is stored locally using Hive.

- **Settings:**  
  Configure API keys, font size, and other preferences. Settings are applied globally throughout the app.

- **Modern UI:**  
  Stylish bottom navigation bar, markdown rendering, and responsive design.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dart 3.x
- [Hive](https://pub.dev/packages/hive) and [hive_flutter](https://pub.dev/packages/hive_flutter)
- [gpt_markdown](https://pub.dev/packages/gpt_markdown)
- [chem_nor](https://pub.dev/packages/chem_nor)

### Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/yourusername/chemnor__it.git
   cd chemnor__it
   ```
2. Install dependencies:
   ```sh
   flutter pub get
   ```
3. Run the app:
   ```sh
   flutter run
   ```

## Usage

- **Searching for Compounds:**  
  Enter a chemical name or formula in the search bar. Select a result to view its details.

- **Interacting with AI:**  
  Use the AI chat to ask questions or get explanations about compounds.

- **Using Chemistry Tools:**  
  Access tools like the "chemist" function from the compound details page.

- **Managing History:**  
  View your search and chat history in the "History" tab. Long-press items for options.

- **Adjusting Settings:**  
  Modify settings in the "Settings" tab to customize your experience.

## Troubleshooting

- **Common Issues:**  
  - If the app crashes on startup, ensure all dependencies are correctly installed.
  - For API-related issues, double-check your API keys in the settings.

- **Getting Help:**  
  - Consult the [Flutter documentation](https://docs.flutter.dev/) for general Flutter issues.
  - Check the [GitHub issues page](https://github.com/yourusername/chemnor__it/issues) for known issues and solutions.

## Contributing

1. Fork the repository.
2. Create a new branch for your feature or bugfix:
   ```sh
   git checkout -b my-feature-branch
   ```
3. Make your changes and commit them:
   ```sh
   git commit -m "Add some feature"
   ```
4. Push to the branch:
   ```sh
   git push origin my-feature-branch
   ```
5. Create a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the need for intelligent and accessible chemistry tools.
- Leveraging powerful APIs like ChemNOR and Gemini for AI capabilities.
- Built with Flutter for a smooth and responsive user experience.
