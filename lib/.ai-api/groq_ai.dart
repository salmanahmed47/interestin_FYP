import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';


Future<String> classifyEvent(String description) async {
  const String apiKey = "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"; // Replace with your API Key
  const String apiUrl = "https://api.groq.com/openai/v1/chat/completions";

  const List<String> categories = [
    "Academic",
    "Cultural",
    "Sports",
    "Social",
    "Technical",
    "Community",
    "Entertainment",
    "Religious"
  ];

  log("Description: $description");
  log("Categories: $categories");

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {
            "role": "user",
            "content":
                "Classify the following event description into one of these categories: $categories. If it doesn't fit, return 'General'. Respond with ONLY the category name as a single word. No extra text.\n\nDescription: $description"
          }
        ],
        "max_tokens": 10
      }),
    );

    log("Response status: ${response.statusCode}");
    log("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      String category = data["choices"][0]["message"]["content"].trim();

      // Ensure response is exactly one of the expected categories
      return categories.contains(category) ? category : "General";
    } else {
      return "General"; // Default to General if API fails
    }
  } catch (e) {
    log("Error: $e");
    return "General"; // Default to General if an exception occurs
  }
}
