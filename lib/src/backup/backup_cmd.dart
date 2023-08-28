import 'package:args/command_runner.dart';

import 'backup_init.dart';

class BackupCmd extends Command<int> {
  BackupCmd() {
    addSubcommand(BackupInit());
  }

  @override
  String get description => 'Manage backup remotes';

  @override
  String get name => 'backup';
}
