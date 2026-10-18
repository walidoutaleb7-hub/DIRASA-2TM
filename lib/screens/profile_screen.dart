import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _statusController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _pickedImageBytes;

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 300);
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _pickedImageBytes = bytes);
    }
  }

  void _saveProfile(String currentStatus) async {
    setState(() => _isLoading = true);
    
    if (_pickedImageBytes != null) {
      await AuthService.updateProfileImage(_pickedImageBytes!);
    }
    
    if (_statusController.text.trim().isNotEmpty && _statusController.text != currentStatus) {
      await AuthService.updateStatus(_statusController.text.trim());
    }

    setState(() {
      _isLoading = false;
      _pickedImageBytes = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var user = snapshot.data!.data() as Map<String, dynamic>;
          String currentStatus = user['status'] ?? 'متاح للدراسة';
          
          if (_statusController.text.isEmpty) {
            _statusController.text = currentStatus;
          }

          // استخراج الصورة (سواء المختارة حديثاً أو المحفوظة)
          Uint8List? imageBytes;
          if (_pickedImageBytes != null) {
            imageBytes = _pickedImageBytes;
          } else if (user['profileImage'] != null && user['profileImage'].toString().isNotEmpty) {
            imageBytes = base64Decode(user['profileImage']);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.cardColor,
                        backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                        child: imageBytes == null ? const Icon(Icons.person, size: 60, color: AppTheme.textSecondary) : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(user['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${user['studyTime'] ?? 0} دقيقة دراسة', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                
                TextField(
                  controller: _statusController,
                  decoration: const InputDecoration(
                    labelText: 'الحالة (ماذا تفعل الآن؟)',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _saveProfile(currentStatus),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ التغييرات'),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
