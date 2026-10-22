import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatefulWidget {
  final String userId;
  final String name;
  final double radius;

  const UserAvatar({super.key, required this.userId, required this.name, this.radius = 16});

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  static final Map<String, Uint8List?> _cache = {};
  Uint8List? _imageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (_cache.containsKey(widget.userId)) {
      setState(() {
        _imageBytes = _cache[widget.userId];
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final data = doc.data();
      if (data != null && data['profileImage'] != null) {
        final bytes = base64Decode(data['profileImage'] as String);
        _cache[widget.userId] = bytes;
        if (mounted) {
          setState(() {
            _imageBytes = bytes;
            _isLoading = false;
          });
        }
      } else {
        _cache[widget.userId] = null;
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CircleAvatar(radius: widget.radius, backgroundColor: Colors.white10, child: Icon(Icons.person, size: widget.radius, color: Colors.white54));
    }
    if (_imageBytes != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: CircleAvatar(radius: widget.radius, backgroundImage: MemoryImage(_imageBytes!)),
      );
    }
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
      child: Text(widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?', style: TextStyle(color: AppTheme.primaryColor, fontSize: widget.radius * 0.8, fontWeight: FontWeight.bold)),
    );
  }
}
