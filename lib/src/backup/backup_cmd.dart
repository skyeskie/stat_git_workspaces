import 'package:args/command_runner.dart';
import 'package:stat_git_workspaces/src/backup/backup_push.dart';

import 'backup_init.dart';

class BackupCmd extends Command<int> {
  BackupCmd() {
    addSubcommand(BackupInit());
    addSubcommand(BackupPush());
  }

  @override
  String get description => 'Manage backup remotes';

  @override
  String get name => 'backup';
}
