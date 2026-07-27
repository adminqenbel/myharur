/// Shared username/display-name validation (mirrors backend rules).
library;

const reservedUsernames = {
  'system', 'support', 'news', 'moderator', 'admin', 'security',
  'notifications', 'maintenance', 'mid', 'root', 'superadmin',
  'super_admin', 'systemadmin', 'system_admin', 'sysadmin', 'sys_admin',
  'api', 'bot', 'official', 'staff', 'help', 'administrator',
  'info', 'contact', 'mail', 'email', 'noreply', 'no_reply',
  'myharur', 'harur', 'anonymous', 'guest', 'null', 'undefined',
  'mod', 'owner', 'webmaster',
};

const abusiveWords = {
  'fuck', 'shit', 'bitch', 'asshole', 'cunt', 'dick', 'pussy',
  'cock', 'slut', 'whore', 'bastard', 'nigger', 'faggot',
  'porn', 'sex', 'rape', 'murder', 'kill', 'nazi',
};

String? validateUsername(String username) {
  if (username.length < 3) return 'Minimum 3 characters';
  if (username.length > 30) return 'Maximum 30 characters';
  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
    return 'Only letters, numbers, underscore';
  }
  final lower = username.toLowerCase();
  if (reservedUsernames.contains(lower)) return '"$username" is reserved';
  for (final word in abusiveWords) {
    if (lower.contains(word)) return 'Contains inappropriate language';
  }
  return null;
}

String? validateDisplayName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Display name cannot be empty';
  if (trimmed.length > 60) return 'Maximum 60 characters';
  final lower = trimmed.toLowerCase();
  for (final word in abusiveWords) {
    if (lower.contains(word)) return 'Contains inappropriate language';
  }
  return null;
}

String? validateNameField(String name, String label) {
  if (name.trim().isEmpty) return null;
  final lower = name.toLowerCase();
  for (final word in abusiveWords) {
    if (lower.contains(word)) return '$label contains inappropriate language';
  }
  return null;
}
