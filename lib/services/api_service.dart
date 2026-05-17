import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // The base URL of your Hugging Face Space
  static const String baseUrl =
      "https://nillohitroy-cogniscript-medical-ai.hf.space";

  static Future<Map<String, dynamic>> analyzePrescription(
    File imageFile,
  ) async {
    try {
      // Prepare the Image
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final imageUri = "data:image/jpeg;base64,$base64Image";

      // ---------------------------------------------------------
      // STEP 1: Submit the image to the Gradio Queue
      // ---------------------------------------------------------
      final postResponse = await http.post(
        Uri.parse("$baseUrl/gradio_api/call/predict"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "data": [
            {
              "meta": {"_type": "gradio.FileData"},
              "url": imageUri,
            },
          ],
        }),
      );

      if (postResponse.statusCode != 200) {
        throw Exception(
          "Server Error on Submission: ${postResponse.statusCode}",
        );
      }

      // The server returns an event ID (our "ticket" in the queue)
      final eventId = jsonDecode(postResponse.body)['event_id'];

      // ---------------------------------------------------------
      // STEP 2 & 3: Listen to the Live SSE Stream (Prevents Timeouts)
      // ---------------------------------------------------------
      // Instead of a single 'get', we open a streaming request
      final request = http.Request(
        'GET', 
        Uri.parse("$baseUrl/gradio_api/call/predict/$eventId")
      );
      
      final streamedResponse = await request.send();
      String accumulatedData = "";

      // Listen to the heartbeat as the data trickles in
      await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
        accumulatedData += chunk;

        // If we see the complete flag, extract the data and close the stream
        if (accumulatedData.contains('event: complete')) {
          final parts = accumulatedData.split('event: complete');
          final completeSection = parts.last;

          final dataIndex = completeSection.indexOf('data: ');
          if (dataIndex != -1) {
            final jsonString = completeSection.substring(dataIndex + 6).trim();
            final dataArray = jsonDecode(jsonString);

            final String aiOutputString = dataArray[0];

            // --- THE BULLETPROOF JSON EXTRACTOR ---
            int startIndex = aiOutputString.indexOf('{');
            int endIndex = aiOutputString.lastIndexOf('}');

            if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
              String cleanJson = aiOutputString.substring(startIndex, endIndex + 1);
              return jsonDecode(cleanJson); 
            } else {
              throw Exception("The AI's response was cut off or did not contain JSON.");
            }
          }
        } 
        // If the server explicitly throws an error during the stream
        else if (accumulatedData.contains('event: error')) {
          throw Exception("Hugging Face API returned an error during processing.");
        }
      }

      throw Exception("Connection closed before the AI finished thinking.");
      
    } on FormatException catch (e) {
      throw Exception(
        "AI returned invalid JSON formatting. Please try scanning again.\nError: $e",
      );
    } on SocketException {
      throw Exception("No Internet connection or the server is unreachable.");
    } catch (e) {
      throw Exception("API Connection Failed: $e");
    }
  }
}