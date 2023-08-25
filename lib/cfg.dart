import 'dart:io';

abstract class Config {
  const Config();

  factory Config.get() => HardcodedConfig();

  /// Directory containing Git repo projects
  /// Assumes each folder is a project
  Directory getWorkspaceDir();

  /// User for backup git repo
  /// TODO: Differentiate since each remote could have different users
  String get user;

  /// Backup server hostname (with port)
  String get backupServer;

  /// Generate SSH URI used by backup Git server (git@host:user/repo)
  String getBackupUri({required String repositoryName, String? userOrGroup});

  /// Name to use for backup remote
  String get backupRemoteName => 'backup';

  /// Name to use for upstream remote (origin is fork)
  String get upstreamRemoteName => 'upstream';

  /// Name to use for primary remote
  String get originRemoteName => 'origin';
}

/// Hardcoded configuration in dart
/// TODO replace with (CLI overrides) > (config file) > (hardcoded)
class HardcodedConfig extends Config {
  const HardcodedConfig();

  @override
  String get user => 'sky';

  @override
  String get backupServer => 'home.yeskie.net';

  @override
  String get backupRemoteName => 'nas';

  @override
  String getBackupUri({required String repositoryName, String? userOrGroup}) {
    String bucket = userOrGroup ?? user;
    return 'git@$backupServer:$bucket/$repositoryName';
  }

  @override
  Directory getWorkspaceDir() => Directory('/home/sky/ws/');
}
