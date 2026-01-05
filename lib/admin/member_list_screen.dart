// ignore_for_file: prefer_final_fields, deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import '../models/member_model.dart';
import '../services/family_service.dart';
import '../services/imagekit_config.dart';
import '../services/member_service.dart';
import '../services/session_manager.dart';
import 'package:http/http.dart' as http;

// Placeholder for AddMemberScreen
class AddMemberScreen extends StatefulWidget {
  final String familyDocId;
  final String familyName;

  const AddMemberScreen({
    super.key,
    required this.familyDocId,
    required this.familyName,
  });

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _gotraCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _googleMapLinkCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _nativeHomeCtrl = TextEditingController();
  final _parentMidCtrl = TextEditingController();
  final _dktFamilyIdCtrl = TextEditingController();
  String? _profilePhotoUrl;
  final ImagePicker _imagePicker = ImagePicker();

  String _bloodGroup = '';
  String _marriageStatus = 'unmarried';
  List<String> _tags = [];
  List<Map<String, String>> _firms = [];
  bool _loading = false;

  Future<void> _launchWhatsApp() async {
    final url = 'https://wa.me/${_whatsappCtrl.text.trim()}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _launchInstagram() async {
    final username = _instagramCtrl.text.trim();
    final url = username.startsWith('https://') 
        ? username 
        : 'https://instagram.com/$username';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _launchFacebook() async {
    final username = _facebookCtrl.text.trim();
    final url = username.startsWith('https://') 
        ? username 
        : 'https://facebook.com/$username';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _launchMap(String mapUrl) async {
    if (mapUrl.isNotEmpty && await canLaunchUrl(Uri.parse(mapUrl))) {
      await launchUrl(Uri.parse(mapUrl));
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: ImageKitConfig.maxImageWidth.toDouble(),
        maxHeight: ImageKitConfig.maxImageHeight.toDouble(),
        imageQuality: ImageKitConfig.imageQuality,
      );
      
      if (image != null) {
        // Upload to ImageKit
        try {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.familyDocId}_${widget.familyName}.jpg';
          
          // Create multipart request
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('https://upload.imagekit.io/api/v1/files/upload'),
          );
          
          // Add file to request
          request.files.add(await http.MultipartFile.fromPath(
            image.path,
            filename: fileName,
          ));
          
          // Add headers for ImageKit authentication
          request.headers.addAll({
            'Accept': 'application/json',
          });
          
          // Add ImageKit authentication to form data
          request.fields['publicKey'] = ImageKitConfig.publicKey;
          request.fields['signature'] = _generateImageKitSignature(
            fileName,
            ImageKitConfig.privateKey,
          );
          request.fields['expire'] = (DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch.toString();
          request.fields['folder'] = ImageKitConfig.profilePhotoFolder;
          
          // Send request
          final response = await request.send();
          
          if (response.statusCode == 200) {
            final responseData = json.decode(response.bodyBytes);
            final imageUrl = responseData['url'];
            print('ImageKit upload successful: $imageUrl');
            
            setState(() {
              _profilePhotoUrl = imageUrl;
            });
          } else {
            print('ImageKit upload failed: ${response.statusCode}');
            print('Response body: ${response.body}');
            
            // Fallback to local path if upload fails
            setState(() {
              _profilePhotoUrl = image.path;
            });
          }
        } catch (e) {
          print('ImageKit upload error: $e');
          
          // Fallback to local path if upload fails
          setState(() {
            _profilePhotoUrl = image.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Get family data for familyId
      final familyDoc = await FirebaseFirestore.instance
          .collection('families')
          .doc(widget.familyDocId)
          .get();
      final familyData = familyDoc.data() as Map<String, dynamic>;
      final familyId = familyData['familyId'].toString();

      await MemberService().addMember(
        familyDocId: widget.familyDocId,
        familyId: _dktFamilyIdCtrl.text.trim().isEmpty 
            ? familyId 
            : _dktFamilyIdCtrl.text.trim(),
        familyName: widget.familyName,
        fullName: _fullNameCtrl.text.trim(),
        surname: _surnameCtrl.text.trim(),
        fatherName: _fatherNameCtrl.text.trim(),
        motherName: _motherNameCtrl.text.trim(),
        gotra: _gotraCtrl.text.trim(),
        birthDate: _birthDateCtrl.text.trim(),
        bloodGroup: _bloodGroup,
        marriageStatus: _marriageStatus,
        nativeHome: _nativeHomeCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        googleMapLink: _googleMapLinkCtrl.text.trim(),
        firms: _firms,
        whatsapp: _whatsappCtrl.text.trim(),
        instagram: _instagramCtrl.text.trim(),
        facebook: _facebookCtrl.text.trim(),
        tags: _tags,
        parentMid: _parentMidCtrl.text.trim(),
        photoUrl: _profilePhotoUrl ?? '',
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Add Member'),
            backgroundColor: Colors.blue.shade900,
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Profile Photo
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickProfilePhoto,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue.shade900,
                          backgroundImage: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                              ? (_profilePhotoUrl!.startsWith('http') 
                                  ? NetworkImage(_profilePhotoUrl!)
                                  : FileImage(File(_profilePhotoUrl!)))
                              : null,
                          child: _profilePhotoUrl == null || _profilePhotoUrl!.isEmpty
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 36,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to add profile photo',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Personal Info
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _surnameCtrl,
                  decoration: const InputDecoration(labelText: 'Surname'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fatherNameCtrl,
                  decoration: const InputDecoration(labelText: 'Father Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motherNameCtrl,
                  decoration: const InputDecoration(labelText: 'Mother Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _gotraCtrl,
                  decoration: const InputDecoration(labelText: 'Gotra'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _birthDateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Birth Date (dd/MM/yyyy) *',
                    hintText: '15/08/1990',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _bloodGroup.isEmpty ? null : _bloodGroup,
                  decoration: const InputDecoration(labelText: 'Blood Group'),
                  items: ['', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                      .map(
                        (bg) => DropdownMenuItem(
                          value: bg,
                          child: Text(bg.isEmpty ? 'Select' : bg),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _bloodGroup = v ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _marriageStatus,
                  decoration: const InputDecoration(
                    labelText: 'Marriage Status',
                  ),
                  items: ['unmarried', 'married']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _marriageStatus = v ?? 'unmarried'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nativeHomeCtrl,
                  decoration: const InputDecoration(labelText: 'Native Home'),
                ),

                // Contact Info
                const SizedBox(height: 20),
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _googleMapLinkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Google Map Link',
                    hintText: 'https://maps.google.com/...',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _whatsappCtrl,
                  decoration: const InputDecoration(labelText: 'WhatsApp'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instagramCtrl,
                  decoration: const InputDecoration(labelText: 'Instagram'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _facebookCtrl,
                  decoration: const InputDecoration(labelText: 'Facebook'),
                ),

                // Firms/Business Details
                const SizedBox(height: 20),
                const Text(
                  'Firms / Business Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._firms.asMap().entries.map((entry) {
                  final index = entry.key;
                  final firm = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: firm['name'],
                                decoration: const InputDecoration(
                                  labelText: 'Firm Name',
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  _firms[index]['name'] = value;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _firms.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        TextFormField(
                          initialValue: firm['phone'],
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            _firms[index]['phone'] = value;
                          },
                        ),
                        TextFormField(
                          initialValue: firm['mapLink'],
                          decoration: const InputDecoration(
                            labelText: 'Map Link',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            _firms[index]['mapLink'] = value;
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _firms.add({'name': '', 'phone': '', 'mapLink': ''});
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Firm'),
                ),

                // Family Information
                const SizedBox(height: 20),
                const Text(
                  'Family Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dktFamilyIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'DKT Family ID',
                    hintText: 'Enter DKT Family ID',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _parentMidCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Parent Member ID',
                    hintText: 'Enter parent MID (optional)',
                  ),
                ),

                // Tags (Admin Only)
                const SizedBox(height: 20),
                const Text(
                  'Tags',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
            // Visible tag input field
            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Add Tag (max 15 chars)',
                hintText: 'Enter tag and press + button',
              ),
              maxLength: 15,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: const SizedBox.shrink(), // Empty space
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final v = _tagsCtrl.text.trim();
                    if (v.isNotEmpty &&
                        v.length <= 15 &&
                        !_tags.contains(v)) {
                      setState(() {
                        _tags.add(v);
                        _tagsCtrl.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  );
                }).toList(),
              ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Add Member'),
                ),
                const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        // Loading overlay
        if (_loading)
          Container(
            color: Colors.black45,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Adding member...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class EditMemberScreen extends StatefulWidget {
  final String memberId;
  final String familyDocId;

  const EditMemberScreen({
    super.key,
    required this.memberId,
    required this.familyDocId,
  });

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _gotraCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _googleMapLinkCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _nativeHomeCtrl = TextEditingController();
  final _parentMidCtrl = TextEditingController();
  final _dktFamilyIdCtrl = TextEditingController();
  String? _profilePhotoUrl;
  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, String>> _firms = [];
  String _bloodGroup = '';
  String _marriageStatus = 'unmarried';
  List<String> _tags = [];
  bool _loading = true;

  Future<void> _launchWhatsApp() async {
    final url = 'https://wa.me/${_whatsappCtrl.text.trim()}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _launchInstagram() async {
    final username = _instagramCtrl.text.trim();
    final url = username.startsWith('https://') 
        ? username 
        : 'https://instagram.com/$username';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _launchFacebook() async {
    final username = _facebookCtrl.text.trim();
    final url = username.startsWith('https://') 
        ? username 
        : 'https://facebook.com/$username';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _launchMap(String mapUrl) async {
    if (mapUrl.isNotEmpty && await canLaunchUrl(Uri.parse(mapUrl))) {
      await launchUrl(Uri.parse(mapUrl));
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: ImageKitConfig.maxImageWidth.toDouble(),
        maxHeight: ImageKitConfig.maxImageHeight.toDouble(),
        imageQuality: ImageKitConfig.imageQuality,
      );
      
      if (image != null) {
        // Upload to ImageKit
        try {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.familyDocId}_${widget.memberId}.jpg';
          
          // Create multipart request
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('https://upload.imagekit.io/api/v1/files/upload'),
          );
          
          // Add file to request
          request.files.add(await http.MultipartFile.fromPath(
            image.path,
            filename: fileName,
          ));
          
          // Add headers for ImageKit authentication
          request.headers.addAll({
            'Accept': 'application/json',
          });
          
          // Add ImageKit authentication to form data
          request.fields['publicKey'] = ImageKitConfig.publicKey;
          request.fields['signature'] = _generateImageKitSignature(
            fileName,
            ImageKitConfig.privateKey,
          );
          request.fields['expire'] = (DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch.toString();
          request.fields['folder'] = ImageKitConfig.profilePhotoFolder;
          
          // Send request
          final response = await request.send();
          
          if (response.statusCode == 200) {
            final responseData = json.decode(response.bodyBytes);
            final imageUrl = responseData['url'];
            print('ImageKit upload successful: $imageUrl');
            
            setState(() {
              _profilePhotoUrl = imageUrl;
            });
          } else {
            print('ImageKit upload failed: ${response.statusCode}');
            print('Response body: ${response.body}');
            
            // Fallback to local path if upload fails
            setState(() {
              _profilePhotoUrl = image.path;
            });
          }
        } catch (e) {
          print('ImageKit upload error: $e');
          
          // Fallback to local path if upload fails
          setState(() {
            _profilePhotoUrl = image.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    final member = await MemberService().getMember(
      familyDocId: widget.familyDocId,
      memberId: widget.memberId,
    );
    if (member != null) {
      _fullNameCtrl.text = member.fullName;
      _surnameCtrl.text = member.surname;
      _fatherNameCtrl.text = member.fatherName;
      _motherNameCtrl.text = member.motherName;
      _gotraCtrl.text = member.gotra;
      _birthDateCtrl.text = member.birthDate;
      _phoneCtrl.text = member.phone;
      _addressCtrl.text = member.address;
      _googleMapLinkCtrl.text = member.googleMapLink;
      _whatsappCtrl.text = member.whatsapp;
      _instagramCtrl.text = member.instagram;
      _facebookCtrl.text = member.facebook;
      _bloodGroup = member.bloodGroup;
      _marriageStatus = member.marriageStatus;
      _nativeHomeCtrl.text = member.nativeHome;
      _dktFamilyIdCtrl.text = member.familyId;
      _parentMidCtrl.text = member.parentMid;
      _tags = List.from(member.tags);
      _firms = List.from(member.firms);
      _profilePhotoUrl = member.photoUrl;
    }
    setState(() => _loading = false);
  }

  // Helper function to generate ImageKit signature
  String _generateImageKitSignature(String fileName, String privateKey) {
    final key = utf8.encode(privateKey);
    final expiration = (DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch.toString());
    
    final policy = 'image/${fileName.substring(0, fileName.lastIndexOf('.'))}';
    final signatureData = '$policy\n$expiration\n';
    
    final hmacSha256 = Hmac(sha256, key);
    final signature = hmacSha256.convert(utf8.encode(signatureData));
    
    return base64.encode(signature.bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Member')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Profile Photo
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade900,
                      backgroundImage: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                          ? (_profilePhotoUrl!.startsWith('http') 
                              ? NetworkImage(_profilePhotoUrl!)
                              : FileImage(File(_profilePhotoUrl!)))
                          : null,
                      child: _profilePhotoUrl == null || _profilePhotoUrl!.isEmpty
                          ? const Icon(
                              Icons.camera_alt,
                              size: 36,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to change profile photo',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Personal Information
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name *'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _surnameCtrl,
              decoration: const InputDecoration(labelText: 'Surname'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fatherNameCtrl,
              decoration: const InputDecoration(labelText: 'Father Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motherNameCtrl,
              decoration: const InputDecoration(labelText: 'Mother Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gotraCtrl,
              decoration: const InputDecoration(labelText: 'Gotra'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _birthDateCtrl,
              decoration: const InputDecoration(
                labelText: 'Birth Date (dd/MM/yyyy)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _bloodGroup.isEmpty ? null : _bloodGroup,
              decoration: const InputDecoration(labelText: 'Blood Group'),
              items: ['', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                  .map(
                    (bg) => DropdownMenuItem(
                      value: bg,
                      child: Text(bg.isEmpty ? 'Select' : bg),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _bloodGroup = v ?? ''),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _marriageStatus,
              decoration: const InputDecoration(labelText: 'Marriage Status'),
              items: ['unmarried', 'married']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _marriageStatus = v ?? 'unmarried'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nativeHomeCtrl,
              decoration: const InputDecoration(labelText: 'Native Home'),
            ),

            // Contact Information
            const SizedBox(height: 20),
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _googleMapLinkCtrl,
              decoration: const InputDecoration(
                labelText: 'Google Map Link',
                hintText: 'https://maps.google.com/...',
              ),
            ),

            // Social Media
            const SizedBox(height: 20),
            const Text(
              'Social Media',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // WhatsApp
                Column(
                  children: [
                    IconButton(
                      onPressed: _whatsappCtrl.text.trim().isNotEmpty ? _launchWhatsApp : null,
                      icon: const Icon(Icons.message, color: Colors.green),
                      iconSize: 40,
                    ),
                    const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                  ],
                ),
                // Instagram
                Column(
                  children: [
                    IconButton(
                      onPressed: _instagramCtrl.text.trim().isNotEmpty ? _launchInstagram : null,
                      icon: const Icon(Icons.camera_alt, color: Colors.purple),
                      iconSize: 40,
                    ),
                    const Text('Instagram', style: TextStyle(fontSize: 12)),
                  ],
                ),
                // Facebook
                Column(
                  children: [
                    IconButton(
                      onPressed: _facebookCtrl.text.trim().isNotEmpty ? _launchFacebook : null,
                      icon: const Icon(Icons.facebook, color: Colors.blue),
                      iconSize: 40,
                    ),
                    const Text('Facebook', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            // Hidden text fields for storing values
            TextFormField(
              controller: _whatsappCtrl,
              decoration: const InputDecoration(
                labelText: 'WhatsApp Number',
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() {}),
            ),
            TextFormField(
              controller: _instagramCtrl,
              decoration: const InputDecoration(
                labelText: 'Instagram Username',
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() {}),
            ),
            TextFormField(
              controller: _facebookCtrl,
              decoration: const InputDecoration(
                labelText: 'Facebook Username',
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() {}),
            ),

            // Firms/Business Details
            const SizedBox(height: 20),
            const Text(
              'Firms / Business Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._firms.asMap().entries.map((entry) {
              final index = entry.key;
              final firm = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: firm['name'],
                            decoration: const InputDecoration(
                              labelText: 'Firm Name',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              _firms[index]['name'] = value;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _firms.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    TextFormField(
                      initialValue: firm['phone'],
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _firms[index]['phone'] = value;
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: firm['mapLink'],
                            decoration: const InputDecoration(
                              labelText: 'Map Link',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              _firms[index]['mapLink'] = value;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue),
                          onPressed: firm['mapLink']?.isNotEmpty == true 
                              ? () => _launchMap(firm['mapLink']!)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _firms.add({'name': '', 'phone': '', 'mapLink': ''});
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Firm'),
            ),

            // Family Information
            const SizedBox(height: 20),
            const Text(
              'Family Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dktFamilyIdCtrl,
              decoration: const InputDecoration(
                labelText: 'DKT Family ID',
                hintText: 'Enter DKT Family ID',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _parentMidCtrl,
              decoration: const InputDecoration(
                labelText: 'Parent Member ID',
                hintText: 'Enter parent MID (optional)',
              ),
            ),

            // Tags
            const SizedBox(height: 20),
            const Text(
              'Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Visible tag input field
            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Add Tag (max 15 chars)',
                hintText: 'Enter tag and press + button',
              ),
              maxLength: 15,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: const SizedBox.shrink(), // Empty space
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final v = _tagsCtrl.text.trim();
                    if (v.isNotEmpty && v.length <= 15 && !_tags.contains(v)) {
                      setState(() {
                        _tags.add(v);
                        _tagsCtrl.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                await MemberService().updateMember(
                  familyDocId: widget.familyDocId,
                  memberId: widget.memberId,
                  updates: {
                    'fullName': _fullNameCtrl.text.trim(),
                    'surname': _surnameCtrl.text.trim(),
                    'fatherName': _fatherNameCtrl.text.trim(),
                    'motherName': _motherNameCtrl.text.trim(),
                    'gotra': _gotraCtrl.text.trim(),
                    'birthDate': _birthDateCtrl.text.trim(),
                    'bloodGroup': _bloodGroup,
                    'marriageStatus': _marriageStatus,
                    'nativeHome': _nativeHomeCtrl.text.trim(),
                    'phone': _phoneCtrl.text.trim(),
                    'address': _addressCtrl.text.trim(),
                    'googleMapLink': _googleMapLinkCtrl.text.trim(),
                    'whatsapp': _whatsappCtrl.text.trim(),
                    'instagram': _instagramCtrl.text.trim(),
                    'facebook': _facebookCtrl.text.trim(),
                    'firms': _firms,
                    'tags': _tags,
                    'parentMid': _parentMidCtrl.text.trim(),
                    'familyId': _dktFamilyIdCtrl.text.trim(),
                    'photoUrl': _profilePhotoUrl ?? '',
                  },
                );

                Navigator.pop(context);
              },
              child: const Text('Update Member'),
            ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class MemberListScreen extends StatefulWidget {
  final String familyDocId;
  final String familyName;

  const MemberListScreen({
    super.key,
    required this.familyDocId,
    required this.familyName,
  });

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> with WidgetsBindingObserver {
  late Stream<QuerySnapshot> _membersStream;
  String _searchQuery = '';
  String _selectedTag = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _membersStream = FirebaseFirestore.instance
        .collection('families')
        .doc(widget.familyDocId)
        .collection('members')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh the stream when app resumes
      setState(() {
        _membersStream = FirebaseFirestore.instance
            .collection('families')
            .doc(widget.familyDocId)
            .collection('members')
            .orderBy('createdAt', descending: true)
            .snapshots();
      });
    }
  }

  // Helper function to generate ImageKit signature
  String _generateImageKitSignature(String fileName, String privateKey) {
    final algorithm = Hmac.sha256;
    final key = utf8.encode(privateKey);
    final expiration = (DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch.toString());
    
    final policy = 'image/${fileName.substring(0, fileName.lastIndexOf('.'))}';
    final signatureData = '$policy\n$expiration\n';
    
    final signature = base64.encode(hmac.convert(signatureData, key));
    
    return base64.encode(signature);
  }

  // Helper function to build initials widget
  Widget _buildInitials(Map<String, dynamic> data) {
    return Container(
      width: 60,
      height: 60,
      color: Colors.blue.shade900,
      child: Center(
        child: Text(
          (data['fullName'] ?? '?')[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.familyName),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMemberScreen(
                    familyDocId: widget.familyDocId,
                    familyName: widget.familyName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search members...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          FutureBuilder<List<String>>(
            future: MemberService().getAllTags(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final tags = snapshot.data!;
              return SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    final isSelected = _selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTag = selected ? tag : '';
                          });
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _membersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No members found'));
                }

                final members = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fullName = (data['fullName'] ?? '').toLowerCase();
                  final searchLower = _searchQuery.toLowerCase();
                  final matchesSearch = fullName.contains(searchLower);
                  final tags = List<String>.from(data['tags'] ?? []);
                  final matchesTag =
                      _selectedTag.isEmpty || tags.contains(_selectedTag);
                  return matchesSearch && matchesTag;
                }).toList();

                if (members.isEmpty) {
                  return const Center(
                    child: Text('No members match your search'),
                  );
                }

                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final doc = members[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final tags = List<String>.from(data['tags'] ?? []);
                    final isActive = data['isActive'] as bool? ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      elevation: 3,
                      color: isActive ? Colors.white : Colors.grey.shade200,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MemberDetailScreen(
                                memberId: doc.id,
                                familyDocId: widget.familyDocId,
                              ),
                            ),
                          );
                        },
                        onLongPress: () async {
                          // Show edit/delete options
                          final result = await showModalBottomSheet<String>(
                            context: context,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit, color: Colors.blue),
                                  title: const Text('Edit Member'),
                                  onTap: () => Navigator.pop(context, 'edit'),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: const Text('Delete Member'),
                                  onTap: () => Navigator.pop(context, 'delete'),
                                ),
                              ],
                            ),
                          );
                          
                          if (result == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditMemberScreen(
                                  memberId: doc.id,
                                  familyDocId: widget.familyDocId,
                                ),
                              ),
                            );
                          } else if (result == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Member'),
                                content: const Text(
                                  'Are you sure you want to delete this member?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(context, true);
                                      await MemberService().deleteMember(
                                        familyDocId: widget.familyDocId,
                                        memberId: doc.id,
                                      );
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await MemberService().deleteMember(
                                familyDocId: widget.familyDocId,
                                memberId: doc.id,
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Profile Photo
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.shade900,
                                ),
                                child: ClipOval(
                                  child: (() {
                                    final photoUrl = data['photoUrl'] as String? ?? '';
                                    print('Member photo URL: "$photoUrl"');
                                    print('Photo URL isNotEmpty: ${photoUrl.isNotEmpty}');
                                    print('Photo URL starts with http: ${photoUrl.startsWith('http')}');
                                    if (photoUrl.isNotEmpty && photoUrl.startsWith('http')) {
                                      return Image.network(
                                        photoUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('NetworkImage error: $error');
                                          return _buildInitials(data);
                                        },
                                      );
                                    } else {
                                      print('Using initials fallback');
                                      return _buildInitials(data);
                                    }
                                  })(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Member Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name
                                    Text(
                                      data['fullName'] ?? 'Unnamed',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? Colors.black87
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Surname and Age
                                    Text(
                                      '${data['surname'] ?? ''} • ${data['age'] ?? 0} years',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isActive
                                            ? Colors.black54
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Tags
                                    if (tags.isNotEmpty)
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: tags.take(3).map((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              tag,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              ),
                              // Status Indicator
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddMemberScreen(
                familyDocId: widget.familyDocId,
                familyName: widget.familyName,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
