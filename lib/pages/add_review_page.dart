import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class AddReviewPage extends StatefulWidget {
  const AddReviewPage({super.key});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  XFile? _image;
  Uint8List? _webImageBytes; // ใช้เก็บรูปสำหรับ Web
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      if (kIsWeb) {
        // อ่านไฟล์เป็น Uint8List สำหรับ Web
        final bytes = await pickedImage.readAsBytes();
        setState(() => _webImageBytes = bytes);
      } else {
        setState(() => _image = pickedImage);
      }
    }
  }

  Future<String?> _uploadImage() async {
    // ตรวจสอบว่ามีการเลือกรูปภาพหรือไม่
    if (kIsWeb && _webImageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select an image")));
      return null;
    }
    if (!kIsWeb && _image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select an image")));
      return null;
    }

    final supabase = Supabase.instance.client;

    // ✅ ดึงนามสกุลไฟล์จาก `_image` หรือ `_webImageBytes`
    String extension =
        kIsWeb
            ? '.png' // Web ไม่มี path ให้ใช้ `.png` เป็นค่าเริ่มต้น
            : path.extension(_image!.path); // ✅ ใช้นามสกุลไฟล์ต้นฉบับ

    final fileName =
        'reviews/${DateTime.now().millisecondsSinceEpoch}$extension';

    try {
      if (kIsWeb) {
        await supabase.storage
            .from('review-images')
            .uploadBinary(fileName, _webImageBytes!);
      } else {
        final bytes = await _image!.readAsBytes();
        await supabase.storage
            .from('review-images')
            .uploadBinary(fileName, bytes);
      }
      return supabase.storage.from('review-images').getPublicUrl(fileName);
    } catch (e) {
      if (!mounted) return null;
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
      return null;
    }
  }

  Future<void> _addReview() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final imageUrl = await _uploadImage();
      if (imageUrl == null) {
        setState(() => _isLoading = false);
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('reviews').add({
          'cafe_name': _nameController.text,
          'description': _descriptionController.text,
          'image_url': imageUrl,
          'user_id': FirebaseAuth.instance.currentUser!.uid,
          'timestamp': Timestamp.now(),
        });

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        print(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to add review: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Review')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextFormField(
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return "Please input Cafe name";
                  }
                  return null;
                },
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Cafe Name'),
              ),
              TextFormField(
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return "Please input Description";
                  }
                  return null;
                },
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 10),
              // แสดงตัวอย่างรูปภาพ (รองรับทั้ง Web และ Mobile)
              _webImageBytes != null
                  ? Image.memory(_webImageBytes!, height: 200) // สำหรับ Web
                  : _image != null
                  ? Image.file(File(_image!.path), height: 200) // สำหรับ Mobile
                  : SizedBox(
                    height: 200,
                    child: Center(child: Text("No image selected")),
                  ),

              SizedBox(height: 10),
              ElevatedButton(onPressed: _pickImage, child: Text('Pick Image')),

              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _addReview,
                    child: Text('Add Review'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
