class Person {
  final String id;
  final String firstName;
  final String lastName;
  final int birthYear;
  final Gender gender;
  final String? photoUrl;
  final String? details;
  final List<String> parentIds;
  final List<String> childrenIds;
  final int? age;
  final String? mid;
  final String? relationToHead;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthYear,
    required this.gender,
    this.photoUrl,
    this.details,
    this.parentIds = const [],
    this.childrenIds = const [],
    this.age,
    this.mid,
    this.relationToHead,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}';
  String get birthYearString => 'b. $birthYear';
  int get calculatedAge {
    if (age != null) return age!;
    final now = DateTime.now();
    return now.year - birthYear;
  }
}

enum Gender { male, female }
