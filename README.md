# Quizzer 🎓

An advanced app for learning foreign words effectively with spaced repetition and various interactive question types.

![Screenshot](https://github.com/J-CITY/quizzer/blob/master/screenshot/image.png)

[Trello Board](https://trello.com/b/jpgn0AG8/quizzer)

## ✨ Key Features

- **Google Sheets Integration:** Easily import and synchronize your vocabularies from a simple Google Sheet using its ID.
- **Multiple Question Types:** Diverse learning methods including:
  - Target -> Native & Native -> Target translations
  - Audio comprehension & dictation
  - Image-based flashcards
  - Typing input and word constructor modes
- **Custom Local Lists:** Create and manage customized word lists directly within the app without relying on external sources.
- **Text-to-Speech (TTS):** Automatic pronunciation of target words across multiple supported dictionary languages (English, Japanese, Spanish, German, French, etc.).
- **Smart Training:** Focuses on your mistakes, reviews words at the right time, and tracks your daily streak.
- **Advanced Training Settings:** Customize training queue size, question count, auto-advance features, and sound effects.
- **Statistics & Progress Tracking:** Keep an eye on learned words, items in progress, error rates, and your training streak.
- **Notifications:** Gentle reminders to review your daily words or save your learning streak from resetting.
- **Profile Export/Import:** Never lose your progress—safely export or import your user profile data.

## 🚀 Getting Started

### Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install) SDK installed on your machine.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/J-CITY/quizzer.git
   ```
2. Navigate to the project directory:
   ```bash
   cd quizzer
   ```
3. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 📝 Google Sheets Format
To import your words from Google Sheets, the table must be accessible via link and follow this column structure:
- **A**: ID (Unique Number)
- **B**: Target Word
- **C**: Reading / Transcription
- **D**: Translation
- **E**: Image URL (Optional)
- **F**: Mnemonic Hint (Optional)
