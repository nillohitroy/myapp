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
      // STEP 2: Wait for the AI to process (Listen to the stream)
      // ---------------------------------------------------------
      // http.get will automatically "hang" and wait until the CPU finishes
      // generating the response (around 2 minutes) and closes the connection.
      final getResponse = await http.get(
        Uri.parse("$baseUrl/gradio_api/call/predict/$eventId"),
      );

      final responseString = getResponse.body;

      // ---------------------------------------------------------
      // STEP 3: Parse the Server-Sent Events (SSE) string
      // ---------------------------------------------------------
      // Gradio streams multiple events. We only want the final "complete" block.
      if (responseString.contains('event: complete')) {
        // Isolate the section after the 'event: complete' signal
        final parts = responseString.split('event: complete');
        final completeSection = parts.last;

        // Find the 'data: ' payload in this section
        final dataIndex = completeSection.indexOf('data: ');
        if (dataIndex != -1) {
          // Extract the JSON array string
          final jsonString = completeSection.substring(dataIndex + 6).trim();
          final dataArray = jsonDecode(jsonString);

          // Our AI's text output is the first item
          final String aiOutputString = dataArray[0];

          // Clean the markdown ticks
          String cleanJson = aiOutputString
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          return jsonDecode(cleanJson);
        }
      } else if (responseString.contains('event: error')) {
        throw Exception(
          "Hugging Face API returned an error during processing.",
        );
      }

      throw Exception("Failed to parse the final AI output.");
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
