// lib/models/member_update_request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MemberUpdateRequestModel {
  final String id;
  final String memberId;
  final String memberMid;
  final String memberName;
  final String familyDocId;
  final String subFamilyDocId;
  final String familyName;
  final String requestedByPhone;
  final String requestType; // 'photo_update', 'contact_info', 'personal_details', 'business_info', 'general'
  final String title;
  final String description;
  final Map<String, dynamic> fieldUpdates;
  final String currentPhotoUrl;
  final String newPhotoUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final String adminNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MemberUpdateRequestModel({
    required this.id,
    required this.memberId,
    required this.memberMid,
    required this.memberName,
    required this.familyDocId,
    this.subFamilyDocId = '',
    required this.familyName,
    required this.requestedByPhone,
    required this.requestType,
    required this.title,
    required this.description,
    this.fieldUpdates = const {},
    this.currentPhotoUrl = '',
    this.newPhotoUrl = '',
    this.status = 'pending',
    this.adminNote = '',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'memberMid': memberMid,
      'memberName': memberName,
      'familyDocId': familyDocId,
      'subFamilyDocId': subFamilyDocId,
      'familyName': familyName,
      'requestedByPhone': requestedByPhone,
      'requestType': requestType,
      'title': title,
      'description': description,
      'fieldUpdates': fieldUpdates,
      'currentPhotoUrl': currentPhotoUrl,
      'newPhotoUrl': newPhotoUrl,
      'status': status,
      'adminNote': adminNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory MemberUpdateRequestModel.fromMap(String docId, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return MemberUpdateRequestModel(
      id: docId,
      memberId: map['memberId'] ?? '',
      memberMid: map['memberMid'] ?? '',
      memberName: map['memberName'] ?? '',
      familyDocId: map['familyDocId'] ?? '',
      subFamilyDocId: map['subFamilyDocId'] ?? '',
      familyName: map['familyName'] ?? '',
      requestedByPhone: map['requestedByPhone'] ?? '',
      requestType: map['requestType'] ?? 'general',
      title: map['title'] ?? 'Member Update Request',
      description: map['description'] ?? '',
      fieldUpdates: Map<String, dynamic>.from(map['fieldUpdates'] ?? {}),
      currentPhotoUrl: map['currentPhotoUrl'] ?? '',
      newPhotoUrl: map['newPhotoUrl'] ?? '',
      status: map['status'] ?? 'pending',
      adminNote: map['adminNote'] ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }
}
