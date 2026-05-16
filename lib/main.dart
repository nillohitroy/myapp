import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';

void main() {
  runApp(const CogniScriptApp());
}

class CogniScriptApp extends StatelessWidget {
  const CogniScriptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CogniScript AI',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), 
          primary: const Color(0xFF1E3A8A),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.blue.shade50,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1E3A8A),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  bool _isLoading = false; 
  Map<String, dynamic>? _medicalData; 

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      // OPTIMIZATION: Compress and shrink the image so the API upload is instant
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, 
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _medicalData = null; // Clear old results when a new image is picked
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  // --- THE API CONNECTION METHOD ---
  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.analyzePrescription(_selectedImage!);
      setState(() {
        _medicalData = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade400),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- THE HUMANIZER FILTER ---
  // This catches any raw JSON arrays/objects and strips out robotic brackets
  String _formatAiText(dynamic data) {
    if (data == null) return "No information extracted.";
    
    // If the AI accidentally sent a List, join it nicely
    if (data is List) {
      return data.join(", "); 
    }
    
    // If the AI accidentally sent a Map, join its values
    if (data is Map) {
      return data.values.join("\n"); 
    }
    
    // Convert to string and strip out any residual brackets or quotes
    String cleanText = data.toString();
    cleanText = cleanText.replaceAll(RegExp(r'[\[\]\{\}"]'), '').trim();
    
    return cleanText.isEmpty ? "No information extracted." : cleanText;
  }

  // --- THE SLEEK RESULT CARD WIDGET ---
  Widget _buildMedicalCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: Colors.blue.shade800),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1E3A8A)),
                title: const Text('Photo Gallery', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1E3A8A)),
                title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('CogniScript 🩺', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        // Add extra padding at the bottom so the floating button doesn't cover content
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IMAGE PREVIEW AREA
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100, width: 2),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.document_scanner_outlined, size: 64, color: Colors.blue.shade300),
                          const SizedBox(height: 16),
                          Text(
                            "No document selected.\nTap the button below to scan.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 16),
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // ACTION BUTTON OR LOADING SPINNER
              if (_selectedImage != null && !_isLoading && _medicalData == null)
                ElevatedButton.icon(
                  onPressed: _processImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text("Analyze with CogniScript AI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),

              if (_isLoading)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                    const SizedBox(height: 16),
                    Text(
                      "AI is extracting medical data...\n(This takes a few moments on the free tier)", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.blue.shade700)
                    ),
                  ],
                ),

              // THE RESULT CARDS (WITH THE BULLETPROOF HUMANIZER FILTER)
              if (_medicalData != null) ...[
                const SizedBox(height: 16),
                const Text("Extraction Complete", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 16),
                _buildMedicalCard(
                  "Patient Condition", 
                  _formatAiText(_medicalData!['patient_condition']), 
                  Icons.medical_services
                ),
                _buildMedicalCard(
                  "Medications", 
                  _formatAiText(_medicalData!['medications']), 
                  Icons.medication
                ),
                _buildMedicalCard(
                  "Treatment Plan", 
                  _formatAiText(_medicalData!['treatment_plan']), 
                  Icons.assignment_turned_in
                ),
              ]
            ],
          ),
        ),
      ),
      
      // FLOATING ACTION BUTTON
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showImageSourceActionSheet(context),
        backgroundColor: _selectedImage == null ? const Color(0xFF1E3A8A) : Colors.white, 
        foregroundColor: _selectedImage == null ? Colors.white : const Color(0xFF1E3A8A),
        elevation: 4,
        icon: const Icon(Icons.add_a_photo),
        label: Text(
          _selectedImage == null ? "Scan Prescription" : "Change Image",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}