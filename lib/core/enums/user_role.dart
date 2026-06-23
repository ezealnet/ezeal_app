enum UserRole {
  guest,
  student,
  admin,
  institution,
  counsellor;

  String get displayName {
    switch (this) {
      case UserRole.guest:
        return 'Guest';
      case UserRole.student:
        return 'Student';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.institution:
        return 'Institution';
      case UserRole.counsellor:
        return 'Counsellor';
    }
  }
}
