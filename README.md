# CogniScript AI 🩺

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Hugging Face](https://img.shields.io/badge/Hugging%20Face-FFD21E?style=for-the-badge&logo=huggingface&logoColor=000)

**CogniScript AI** is a mobile application designed to bridge the gap between complex handwritten medical documents and patient comprehension. By leveraging the multimodal capabilities of a fine-tuned vision model hosted on Hugging Face, the app processes images of clinical prescriptions directly from a smartphone camera and translates them into plain, accessible English.

## Features

* **Native On-Device Scanning:** Seamlessly capture or upload handwritten prescriptions using the device's camera or photo gallery.
* **Smart Image Compression:** Images are heavily optimized and compressed on-device before API transmission to ensure rapid upload times even on slow networks.
* **Bulletproof Streaming API:** Built with a custom Server-Sent Events (SSE) streaming architecture to handle long inference times (2+ minutes) on free-tier CPU servers without dropping the connection or timing out.
* **Humanized Data Extraction:** The AI's raw JSON and data structure outputs (arrays, nested maps) are intercepted and parsed into clean, empathetic, and human-readable text for the end user.
* **Indestructible UI:** Type-safe rendering ensures the mobile application remains stable regardless of unpredictable AI formatting outputs.

## Architecture & Tech Stack

* **Frontend:** Flutter & Dart
* **Backend Integration:** Hugging Face Spaces (Gradio 4 API)
* **Model:** Gemma 4B Vision (Fine-tuned via Unsloth)
* **API Protocol:** Asynchronous HTTP REST with SSE (Server-Sent Events) for real-time heartbeat monitoring.

## Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.0 or higher)
* Android Studio or VS Code with Flutter extensions
* A running instance of the CogniScript AI Hugging Face Space.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/nillohitroy/myapp.git
   cd my-app
   ```
2. **Install dependencies**
     ```bash
   flutter pub get
   ```
3. **Configure the API**
    Navigate to lib/services/api_service.dart and ensure the `baseUrl` points to your active Hugging Face Space:
   ```bash
   static const String baseUrl = "[https://your-username-cogniscript-medical-ai.hf.space](https://your-username-cogniscript-medical-ai.hf.space)";
   ```
4. **Run the app**
     ```bash
   flutter run
   ```
4. **Build for Production**
     ```bash
   flutter build apk --release
   ```

## How the Inference Pipeline Works
The Flutter frontend converts the compressed image into a Base64 Data URI.

The payload is pushed to the Gradio 4 /call/predict endpoint, placing the request in the Hugging Face server queue and returning an Event ID.

The app opens a streaming GET request using the Event ID, actively listening to the server's heartbeat to bypass Android's strict 60-second idle timeout limit.

Once the server broadcasts the event: complete flag, the custom Dart extractor isolates the JSON payload, strips away any hallucinations or markdown formatting, and updates the mobile UI.
