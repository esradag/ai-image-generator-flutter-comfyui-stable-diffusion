import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(ImageGeneratorApp());
}

class ImageGeneratorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Image Generator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: ImageGeneratorScreen(),
    );
  }
}

class ImageGeneratorScreen extends StatefulWidget {
  @override
  _ImageGeneratorScreenState createState() => _ImageGeneratorScreenState();
}

class _ImageGeneratorScreenState extends State<ImageGeneratorScreen> {
  TextEditingController _controller = TextEditingController();
  List<String> _imageUrls = [];
  List<String> _previousImageUrls = [];
  bool _isLoading = false;
  String? _selectedImage;

  Future<void> generateImages() async {
    String prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _previousImageUrls = List.from(_imageUrls);
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5001/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _imageUrls = List<String>.from(responseData['image_urls']);
          if (_imageUrls.isNotEmpty) {
            _selectedImage = _imageUrls.first;
          }
        });
      } else {
        throw Exception('Failed to generate images');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Image Generator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                labelText: 'Enter prompt',
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                filled: false,
              ),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _isLoading ? null : generateImages,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, // Text color
              ),
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text(
                      'Generate',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
            ),
            SizedBox(height: 16.0),
            _selectedImage != null
                ? Expanded(
                    flex: 3,
                    child: Image.network(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(),
            SizedBox(height: 16.0),
            (_imageUrls.isNotEmpty || _previousImageUrls.isNotEmpty)
                ? Container(
                    height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: (_imageUrls.isNotEmpty ? _imageUrls : _previousImageUrls).map((imageUrl) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = imageUrl;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
