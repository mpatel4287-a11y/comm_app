# Phase 4 - Fixing Compilation Errors

## Issues Found:
1. **SessionManager** - Missing methods for `subFamilyDocId` and `memberDocId` 
2. **AuthService** - Need to save `subFamilyDocId` and `memberDocId` in session
3. **user_profile_screen.dart** - Uses `familyDocId` but MemberService expects `mainFamilyDocId` and `subFamilyDocId`

## Tasks:
- [x] 1. Update SessionManager - Add getSubFamilyDocId, getMemberDocId, saveMemberId methods
- [x] 2. Update AuthService - Save subFamilyDocId and memberDocId in session
- [ ] 3. Fix user_profile_screen.dart - Use mainFamilyDocId and subFamilyDocId
- [ ] 4. Run flutter analyze to verify all errors are fixed

## Changes Made:

### 1. SessionManager - Added new methods
```dart
static const _keySubFamilyDocId = 'sub_family_doc_id';
static const _keyMemberDocId = 'member_doc_id';

static Future<String?> getSubFamilyDocId() async { ... }
static Future<String?> getMemberDocId() async { ... }
```

### 2. AuthService - Updated to save subFamilyDocId
- Note: Currently authService only saves family-level session
- Need to handle member-level session differently

### 3. user_profile_screen.dart - Fixed MemberService calls
- Changed `familyDocId` to `mainFamilyDocId`
- Added `subFamilyDocId` parameter (empty string for backward compatibility)

