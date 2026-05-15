import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔴 IMPORTANT: Replace "your-username" with your actual Hugging Face username 🔴
  // Make sure the URL ends exactly with /api/predict
  static const String apiUrl = "https://nillohitroy-cogniscript-medical-ai.hf.space/api/predict";

  /// Takes the captured image file, sends it to the Hugging Face AI, 
  /// and returns the structured medical data as a Dart Map.
  static Future<Map<String, dynamic>> analyzePrescription(File imageFile) async {
    try {
      // 1. Prepare the Image
      // Gradio APIs expect images to be sent as Base64 Data URIs
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final imageUri = "data:image/jpeg;base64,$base64Image";

      // 2. Send the Request to Hugging Face
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "data": [imageUri] // Gradio requires inputs to be inside a 'data' array
        }),
      );

      // 3. Process the Response
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // The Gradio API returns its outputs in a 'data' array. 
        // Our AI's text output is the very first item.
        final String aiOutputString = jsonResponse['data'][0]; 
        
        // 4. Clean the Markdown Output
        // The AI might return the string wrapped in ```json ... ``` blocks.
        // We must strip those out so Dart can parse it as raw JSON.
        String cleanJson = aiOutputString
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        // 5. Convert to a Dart Map for the UI
        return jsonDecode(cleanJson);
        
      } else {
        // Handle server-side errors (e.g., Space is sleeping or crashed)
        throw Exception("Server Error: ${response.statusCode} - ${response.body}");
      }
    } on FormatException catch (e) {
      throw Exception("AI returned invalid JSON formatting. Please try scanning again.\nError: $e");
    } on SocketException {
      throw Exception("No Internet connection or the Hugging Face server is unreachable.");
    } catch (e) {
      // Catch any other unexpected errors
      throw Exception("API Connection Failed: $e");
    }
  }
}