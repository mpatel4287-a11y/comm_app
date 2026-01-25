// lib/services/analytics_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for high-level overview stats
  Stream<Map<String, int>> streamOverviewStats() {
    return CombineLatestStream.list([
      _firestore.collection('families').where('isAdmin', isEqualTo: false).snapshots(),
      _firestore.collectionGroup('members').snapshots(),
      _firestore.collection('events').snapshots(),
    ]).asBroadcastStream().map((snapshots) {
      return {
        'totalFamilies': snapshots[0].docs.length,
        'totalMembers': snapshots[1].docs.length,
        'totalEvents': snapshots[2].docs.length,
      };
    });
  }

  // Stream for detailed member distribution
  Stream<Map<String, dynamic>> streamMemberDistribution() {
    return _firestore.collectionGroup('members').snapshots().asBroadcastStream().map((snapshot) {
      int active = 0;
      int inactive = 0;
      int male = 0;
      int female = 0;
      int married = 0;
      int unmarried = 0;
      
      Map<String, int> ageRanges = {
        '0-18': 0,
        '19-35': 0,
        '36-50': 0,
        '50+': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Status
        if (data['isActive'] == true) {
          active++;
        } else {
          inactive++;
        }
        
        // Gender (Support case-insensitive and trimmed values)
        String gender = (data['gender'] ?? '').toString().trim().toLowerCase();
        if (gender == 'male' || gender == 'm') {
          male++;
        } else if (gender == 'female' || gender == 'f') {
          female++;
        }
        
        // Marriage Status
        String mStatus = (data['marriageStatus'] ?? '').toString().trim().toLowerCase();
        if (mStatus == 'married') {
          married++;
        } else {
          unmarried++;
        }

        // Age
        int age = data['age'] ?? 0;
        if (age <= 18) {
          ageRanges['0-18'] = ageRanges['0-18']! + 1;
        } else if (age <= 35) {
          ageRanges['19-35'] = ageRanges['19-35']! + 1;
        } else if (age <= 50) {
          ageRanges['36-50'] = ageRanges['36-50']! + 1;
        } else {
          ageRanges['50+'] = ageRanges['50+']! + 1;
        }
      }

      return {
        'active': active,
        'inactive': inactive,
        'male': male,
        'female': female,
        'married': married,
        'unmarried': unmarried,
        'ageRanges': ageRanges,
      };
    });
  }

  // Stream for family status distribution
  Stream<Map<String, int>> streamFamilyDistribution() {
    return _firestore.collection('families').where('isAdmin', isEqualTo: false).snapshots().asBroadcastStream().map((snapshot) {
      int active = 0;
      int blocked = 0;
      
      for (var doc in snapshot.docs) {
        if (doc.data()['isBlocked'] == true) {
          blocked++;
        } else {
          active++;
        }
      }
      
      return {
        'active': active,
        'blocked': blocked,
        'total': snapshot.docs.length,
      };
    });
  }

  // Stream for user growth (last 6 months)
  Stream<List<Map<String, dynamic>>> streamGrowthData() {
    return _firestore.collectionGroup('members').snapshots().asBroadcastStream().map((snapshot) {
      Map<String, int> months = {};
      final now = DateTime.now();
      
      for (int i = 0; i < 6; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
        months[key] = 0;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          DateTime created;
          if (data['createdAt'] is Timestamp) {
            created = (data['createdAt'] as Timestamp).toDate();
          } else {
            continue;
          }
          
          final key = "${created.year}-${created.month.toString().padLeft(2, '0')}";
          if (months.containsKey(key)) {
            months[key] = months[key]! + 1;
          }
        }
      }

      return months.entries
          .map((e) => {'month': e.key, 'count': e.value})
          .toList()
          .reversed
          .toList();
    });
  }
}



