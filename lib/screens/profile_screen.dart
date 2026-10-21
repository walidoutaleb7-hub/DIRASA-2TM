import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String? currentId = AuthService.currentUserId;
  bool _isEditing = false;
  bool _isLoading = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  Uint8List? _pickedImage;

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20, maxWidth: 300);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _pickedImage = bytes);
    }
  }

  void _saveProfile() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    
    try {
      String? base64Image = _pickedImage != null ? base64Encode(_pickedImage!) : null;
      await AuthService.updateUserData(_nameController.text.trim(), _statusController.text.trim(), base64Image);
      
      if (mounted) {
        setState(() { _isEditing = false; _isLoading = false; _pickedImage = null; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات بنجاح!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: currentId == null
          ? const Center(child: Text('يرجى تسجيل الدخول', style: TextStyle(color: Colors.white)))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(currentId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                var user = snapshot.data!.data() as Map<String, dynamic>? ?? {};

                String name = user['name'] ?? 'مستخدم';
                int studyTime = user['studyTime'] ?? 0;
                String status = user['status'] ?? 'متاح للدراسة';
                
                Timestamp? joined = user['createdAt'];
                String joinDate = joined != null ? DateFormat('yyyy/MM/dd').format(joined.toDate()) : 'عضو جديد';
                
                String? base64Str = user['profileImage'];
                Uint8List? imageBytes;
                if (_pickedImage != null) {
                  imageBytes = _pickedImage;
                } else if (base64Str != null && base64Str.isNotEmpty) {
                  imageBytes = base64Decode(base64Str);
                }

                if (!_isEditing) {
                  _nameController.text = name;
                  _statusController.text = status;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isEditing ? _pickImage : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                              backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                              child: imageBytes == null ? Text(name[0], style: const TextStyle(fontSize: 50, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)) : null,
                            ),
                            if (_isEditing) Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (_isEditing) ...[
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'الاسم', filled: true, fillColor: AppTheme.cardColor),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _statusController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'الحالة', filled: true, fillColor: AppTheme.cardColor),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: ElevatedButton(onPressed: () => setState(() => _isEditing = false), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey), child: const Text('إلغاء'))),
                            const SizedBox(width: 12),
                            Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _saveProfile, child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('حفظ التغييرات'))),
                          ],
                        )
                      ] else ...[
                        Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(status, style: const TextStyle(color: Colors.grey)),
                        TextButton.icon(onPressed: () => setState(() => _isEditing = true), icon: const Icon(Icons.edit, size: 16), label: const Text('تعديل الملف الشخصي')),
                      ],

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard('دقائق الدراسة', '$studyTime', Colors.amber),
                          _buildStatCard('تاريخ الانضمام', joinDate, Colors.blueAccent),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 140, padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
    );
  }
}
