// ignore_for_file: prefer_final_fields, deprecated_member_use, use_build_context_synchronously, avoid_print, depend_on_referenced_packages, unused_element, unused_field

import 'dart:io';


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/member_model.dart';
import '../../services/imagekit_config.dart';
import '../../services/member_service.dart';
import '../../services/photo_service.dart';
import '../user/member_detail_screen.dart';

// Placeholder for AddMemberScreen
class AddMemberScreen extends StatefulWidget {
  final String familyDocId;
  final String familyName;
  final String? subFamilyDocId; // NEW: Optional sub-family ID

  const AddMemberScreen({
    super.key,
    required this.familyDocId,
    required this.familyName,
    this.subFamilyDocId,
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
  final _educationCtrl = TextEditingController(); // Added
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _googleMapLinkCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _nativeHomeCtrl = TextEditingController();
  final _parentMidCtrl = TextEditingController();
  final _dktFamilyIdCtrl = TextEditingController();
  String? _profilePhotoUrl;
  String? _pendingPhotoPath; // Store for upload after member creation
  String? _pendingPhotoId;
  final ImagePicker _imagePicker = ImagePicker();
  final PhotoService _photoService = PhotoService();

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
        // Store the photo path locally for preview and later upload
        setState(() {
          _pendingPhotoPath = image.path;
          _profilePhotoUrl = image.path; // Preview local image
        });
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

      // Get subFamilyId if subFamilyDocId is provided
      String subFamilyId = '';
      if (widget.subFamilyDocId != null) {
        final subFamilyDoc = await FirebaseFirestore.instance
            .collection('families')
            .doc(widget.familyDocId)
            .collection('subfamilies')
            .doc(widget.subFamilyDocId)
            .get();
        subFamilyId = subFamilyDoc.data()?['subFamilyId']?.toString() ?? '';
      }

      // Upload photo first if there's a pending photo
      String photoUrl = '';
      if (_pendingPhotoPath != null && _pendingPhotoPath!.isNotEmpty) {
        try {
          final photoFile = XFile(_pendingPhotoPath!);
          // Generate a temporary member ID for the photo naming
          final tempMemberId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
          final uploadedUrl = await _photoService.uploadProfilePhoto(
            memberId: tempMemberId,
            image: photoFile,
          );
          if (uploadedUrl != null && uploadedUrl.startsWith('http')) {
            photoUrl = uploadedUrl;
          } else {
             // Show error if upload fails
             throw Exception('Failed to get valid photo URL from ImageKit');
          }
        } catch (e) {
          print('Error uploading photo: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Photo upload failed: $e. Member will be added without photo.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // Continue without photo on error, do NOT save local path
          photoUrl = '';
        }
      }

      await MemberService().addMember(
        mainFamilyDocId: widget.familyDocId,
        subFamilyDocId: widget.subFamilyDocId ?? '',
        subFamilyId: subFamilyId,
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
        education: _educationCtrl.text.trim(), // Added
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
        password: _passwordCtrl.text.trim().isEmpty ? '123456' : _passwordCtrl.text.trim(), // Added
        photoUrl: photoUrl,
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
                            backgroundImage:
                                _profilePhotoUrl != null &&
                                    _profilePhotoUrl!.isNotEmpty
                                ? (_profilePhotoUrl!.startsWith('http')
                                      ? NetworkImage(_profilePhotoUrl!)
                                      : FileImage(File(_profilePhotoUrl!)))
                                : null,
                            child:
                                _profilePhotoUrl == null ||
                                    _profilePhotoUrl!.isEmpty
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
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
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
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Member Login Password *',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (v) => (v == null || v.length != 8 || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(v)) 
                      ? 'Must be exactly 8 alphanumeric characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _educationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Education',
                      hintText: 'e.g., B.Tech, MBA',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _birthDateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Birth Date (dd/MM/yyyy) *',
                      hintText: '15/08/1990',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _bloodGroup.isEmpty ? null : _bloodGroup,
                    decoration: const InputDecoration(labelText: 'Blood Group'),
                    items:
                        ['', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
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
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
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
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
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
                  }),
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
  final String? subFamilyDocId; // NEW: Optional sub-family ID

  const EditMemberScreen({
    super.key,
    required this.memberId,
    required this.familyDocId,
    this.subFamilyDocId,
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
  final _educationCtrl = TextEditingController(); // Added
  final _passwordCtrl = TextEditingController(); // Added
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
  String? _pendingPhotoPath; // New: Store local path for upload on save
  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, String>> _firms = [];
  String _bloodGroup = '';
  String _marriageStatus = 'unmarried';
  List<String> _tags = [];
  String _memberMid = ''; // New field
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

  final PhotoService _photoService = PhotoService();

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: ImageKitConfig.maxImageWidth.toDouble(),
        maxHeight: ImageKitConfig.maxImageHeight.toDouble(),
        imageQuality: ImageKitConfig.imageQuality,
      );

      if (image != null) {
        setState(() {
          _pendingPhotoPath = image.path;
          _profilePhotoUrl = image.path; // Preview local image
        });
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
      mainFamilyDocId: widget.familyDocId,
      subFamilyDocId: widget.subFamilyDocId ?? '',
      memberId: widget.memberId,
    );
    if (member != null) {
      _fullNameCtrl.text = member.fullName;
      _surnameCtrl.text = member.surname;
      _fatherNameCtrl.text = member.fatherName;
      _motherNameCtrl.text = member.motherName;
      _gotraCtrl.text = member.gotra;
      _birthDateCtrl.text = member.birthDate;
      _educationCtrl.text = member.education; // Added
      _phoneCtrl.text = member.phone;
      _addressCtrl.text = member.address;
      _googleMapLinkCtrl.text = member.googleMapLink;
      _whatsappCtrl.text = member.whatsapp;
      _instagramCtrl.text = member.instagram;
      _facebookCtrl.text = member.facebook;
      _passwordCtrl.text = member.password; // Added
      _bloodGroup = member.bloodGroup;
      _marriageStatus = member.marriageStatus;
      _nativeHomeCtrl.text = member.nativeHome;
      _dktFamilyIdCtrl.text = member.familyId;
      _parentMidCtrl.text = member.parentMid;
      _tags = List.from(member.tags);
      _firms = List.from(member.firms);
      _profilePhotoUrl = member.photoUrl;
      _memberMid = member.mid;
      if (_memberMid.isEmpty) {
        _memberMid = MemberModel.generateMid(member.familyId, member.subFamilyId);
      }
    }
    setState(() => _loading = false);
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
                        backgroundImage:
                            _profilePhotoUrl != null &&
                                _profilePhotoUrl!.isNotEmpty
                            ? (_profilePhotoUrl!.startsWith('http')
                                  ? NetworkImage(_profilePhotoUrl!)
                                  : FileImage(File(_profilePhotoUrl!)))
                            : null,
                        child:
                            _profilePhotoUrl == null ||
                                _profilePhotoUrl!.isEmpty
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
              if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty)
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _profilePhotoUrl = null;
                        _pendingPhotoPath = null;
                      });
                    },
                    child: const Text(
                      'Remove Photo',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Personal Information
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'MID: $_memberMid',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                  fontSize: 14,
                ),
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
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Member Login Password *',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (v) => (v == null || v.length != 8 || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(v)) 
                  ? 'Must be 8 alphanumeric characters' : null,
              ),
              const SizedBox(height: 12),
              // Education Field
              TextFormField(
                controller: _educationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Education',
                  hintText: 'e.g., B.Tech, MBA',
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
              // Changed Row to Wrap to prevent overflow
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 20,
                runSpacing: 10,
                children: [
                  // WhatsApp
                  Column(
                    children: [
                      IconButton(
                        onPressed: _whatsappCtrl.text.trim().isNotEmpty
                            ? _launchWhatsApp
                            : null,
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
                        onPressed: _instagramCtrl.text.trim().isNotEmpty
                            ? _launchInstagram
                            : null,
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.purple,
                        ),
                        iconSize: 40,
                      ),
                      const Text('Instagram', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  // Facebook
                  Column(
                    children: [
                      IconButton(
                        onPressed: _facebookCtrl.text.trim().isNotEmpty
                            ? _launchFacebook
                            : null,
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
              }),
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
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _loading = true);

                  String photoUrl = _profilePhotoUrl ?? '';

                  // Upload photo if changed
                  if (_pendingPhotoPath != null) {
                    try {
                      final uploadedUrl = await _photoService.uploadProfilePhoto(
                        memberId: widget.memberId,
                        image: XFile(_pendingPhotoPath!),
                      );

                      if (uploadedUrl != null && uploadedUrl.startsWith('http')) {
                        photoUrl = uploadedUrl;
                      } else {
                        throw Exception('Failed to upload photo');
                      }
                    } catch (e) {
                      setState(() => _loading = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Photo upload failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                  } else {
                     // Safety check: if URL is local path but no pending upload, clear it
                     if (photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
                        photoUrl = '';
                     }
                  }

                  try {
                    await MemberService().updateMember(
                      mainFamilyDocId: widget.familyDocId,
                      subFamilyDocId: widget.subFamilyDocId ?? '',
                      memberId: widget.memberId,
                      updates: {
                        'fullName': _fullNameCtrl.text.trim(),
                        'surname': _surnameCtrl.text.trim(),
                        'fatherName': _fatherNameCtrl.text.trim(),
                        'motherName': _motherNameCtrl.text.trim(),
                        'gotra': _gotraCtrl.text.trim(),
                        'birthDate': _birthDateCtrl.text.trim(),
                        'education': _educationCtrl.text.trim(), // Added
                        'bloodGroup': _bloodGroup,
                        'marriageStatus': _marriageStatus,
                        'nativeHome': _nativeHomeCtrl.text.trim(),
                        'mid': _memberMid, // Ensure MID is saved
                        'phone': _phoneCtrl.text.trim(),
                        'address': _addressCtrl.text.trim(),
                        'googleMapLink': _googleMapLinkCtrl.text.trim(),
                        'whatsapp': _whatsappCtrl.text.trim(),
                        'instagram': _instagramCtrl.text.trim(),
                        'facebook': _facebookCtrl.text.trim(),
                        'firms': _firms,
                        'tags': _tags,
                        'parentMid': _parentMidCtrl.text.trim(),
                        'password': _passwordCtrl.text.trim(), // Added
                        'familyId': _dktFamilyIdCtrl.text.trim(),
                        'photoUrl': photoUrl,
                      },
                    );

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    setState(() => _loading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating member: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
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
  final String? subFamilyDocId; // NEW: Optional sub-family ID

  const MemberListScreen({
    super.key,
    required this.familyDocId,
    required this.familyName,
    this.subFamilyDocId,
  });

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen>
    with WidgetsBindingObserver {
  late Stream<QuerySnapshot> _membersStream;
  String _searchQuery = '';
  String _selectedTag = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Use sub-family stream if subFamilyDocId is provided, otherwise use old family stream
    if (widget.subFamilyDocId != null) {
      _membersStream = FirebaseFirestore.instance
          .collection('families')
          .doc(widget.familyDocId)
          .collection('subfamilies')
          .doc(widget.subFamilyDocId)
          .collection('members')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // Fallback to old structure for backward compatibility
      _membersStream = FirebaseFirestore.instance
          .collection('families')
          .doc(widget.familyDocId)
          .collection('members')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
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
        if (widget.subFamilyDocId != null) {
          _membersStream = FirebaseFirestore.instance
              .collection('families')
              .doc(widget.familyDocId)
              .collection('subfamilies')
              .doc(widget.subFamilyDocId)
              .collection('members')
              .orderBy('createdAt', descending: true)
              .snapshots();
        } else {
          _membersStream = FirebaseFirestore.instance
              .collection('families')
              .doc(widget.familyDocId)
              .collection('members')
              .orderBy('createdAt', descending: true)
              .snapshots();
        }
      });
    }
  }

  // Helper function to build initials widget
  Widget _buildInitials(Map<String, dynamic> data) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (data['fullName'] ?? '?')[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
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
                    subFamilyDocId: widget.subFamilyDocId,
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
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search members...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
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

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75, // Adjust card height
                  ),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final doc = members[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isActive = data['isActive'] as bool? ?? true;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MemberDetailScreen(
                              memberId: doc.id,
                              familyDocId: widget.familyDocId,
                              subFamilyDocId: widget.subFamilyDocId,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: isActive ? Colors.white : Colors.grey.shade200,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // PROFILE PHOTO
                              ClipOval(
                                child: (() {
                                  final photoUrl =
                                      data['photoUrl'] as String? ?? '';
                                  if (photoUrl.isNotEmpty &&
                                      photoUrl.startsWith('http')) {
                                    return Image.network(
                                      photoUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return _buildInitials(data);
                                          },
                                    );
                                  } else {
                                    return _buildInitials(data);
                                  }
                                })(),
                              ),
                              const SizedBox(height: 8),

                              Text(
                                data['fullName'] ?? 'Unnamed',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.black87
                                      : Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                data['mid'] ?? 'NO MID',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // SURNAME / ROLE
                              Text(
                                '${data['surname'] ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              
                              // AGE
                              Text(
                                '${data['age'] ?? 0} years',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const Spacer(),

                              // ACTIONS
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // EDIT
                                  _buildCompactAction(
                                    icon: Icons.edit,
                                    color: Colors.blue,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditMemberScreen(
                                            memberId: doc.id,
                                            familyDocId: widget.familyDocId,
                                            subFamilyDocId: widget.subFamilyDocId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // DELETE
                                  _buildCompactAction(
                                    icon: Icons.delete,
                                    color: Colors.red,
                                    onTap: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Delete Member'),
                                          content: const Text(
                                            'Are you sure you want to delete this member?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await MemberService().deleteMember(
                                          mainFamilyDocId: widget.familyDocId,
                                          subFamilyDocId:
                                              widget.subFamilyDocId ?? '',
                                          memberId: doc.id,
                                        );
                                      }
                                    },
                                  ),
                                ],
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
                subFamilyDocId: widget.subFamilyDocId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
