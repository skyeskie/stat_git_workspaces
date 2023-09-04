import 'dart:async';

import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/dir_stat.dart';
import 'package:stat_git_workspaces/src/core/multi_command.dart';
import 'package:stat_git_workspaces/src/setup/status_table_builder.dart';

class BackupPush extends StatusMultiCommand with StatusTableBuilder {
  BackupPush() {
    argParser.addFlag(
      'all',
      abbr: 'a',
      negatable: true,
      help: 'Push all refs',
    );
    argParser.addFlag(
      'tags',
      abbr: 't',
      negatable: true,
      defaultsTo: true,
      help: 'Push all tags',
    );
  }

  @override
  String get description => 'Push changes to bakcup server';

  @override
  String get describeInitAction => 'Pushing changes to backup remote';

  @override
  String get name => 'push';

  static const statusMissing = StatusResult(
    description: 'Existing',
    color: AnsiColor.orange1,
  );

  @override
  FutureOr<int>? run() {
    print(
      'Pushing repositories. Watch for auth requests'
          .withForegroundColor(AnsiColor.yellow)
          .bold(),
    );
    return super.run();
  }

  @override
  Future<StatusResult> processGitRepo(GitRepo repo, CommandMode mode) async {
    if (await repo.backup == null) return statusMissing;
    final String backupRemoteName = globalResults!['backup-remote-name'];
    final cmd = ['push', backupRemoteName];
    final bool pushAll = argResults!['all'];
    if (pushAll) {
      cmd.add('--all');
    } else {
      final pushTags = argResults!['tags'];
      if (pushTags) cmd.add('--tags');
    }

    final gitCommand = repo.runGitCmd(cmd);
    if (await gitCommand.run()) {
      return StatusResult.success();
    } else {
      return StatusResult.error(
        trimErrorResult(await gitCommand.stderr),
      );
    }
  }

  static String trimErrorResult(String errorOutput) {
    if (errorOutput.contains('rejected')) return 'Rejected. Fetch first';
    if (errorOutput.contains('Could not read from remote')) {
      return 'No access to remote';
    }
    if (errorOutput.contains('No refs in common')) return 'No refs in common';
    return errorOutput.split('\n').first;
  }
}
