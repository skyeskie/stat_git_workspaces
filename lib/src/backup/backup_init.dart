import 'package:ansix/ansix.dart';
import 'package:interact/interact.dart';
import 'package:stat_git_workspaces/src/core/dir_stat.dart';
import 'package:stat_git_workspaces/src/core/multi_command.dart';
import 'package:stat_git_workspaces/src/setup/status_table_builder.dart';

import '../util/repository_url.dart';

class BackupInit extends MultiCommand {
  BackupInit() {
    argParser.addOption(
      'user',
      abbr: 'u',
    );
  }

  final builder = StatusTableBuilder();

  @override
  String get description => 'Create backup remote for repositories missing one';

  @override
  String get name => 'init';

  static const statusExisting = StatusResult(
    description: 'Existing',
    color: AnsiColor.darkGreen,
  );

  @override
  Future<void> processGitRepo(GitRepo repo, CommandMode mode) async {
    if (await repo.backup != null) return builder.add(repo, statusExisting);
    final repoName = repo.name;

    var org = argResults?['user'];
    if (org == null) {
      final menuItems = [config.user, 'forks', 'redstone', '<input>'];
      final selIndex = Select(
        prompt: 'Select user or organization for $repoName',
        options: [config.user, 'forks', 'redstone', '<input>'],
      ).interact();
      org = menuItems[selIndex];
      if (org == '<input>') {
        org = Input(
          prompt: 'Input user/organization for $repoName:',
          defaultValue: config.user,
        ).interact();
      }
    }

    final url = makeSshRepositoryUrl(
      userInfo: 'git',
      host: config.backupServer,
      repoName: repoName,
      siteUser: org,
    );

    final backupRemoteName =
        globalResults?['backup-remote-name'] ?? config.backupRemoteName;

    final cmd = repo.runGitCmd([
      'remote',
      'add',
      backupRemoteName,
      url.toString(),
    ]);

    if (await cmd.run()) {
      builder.add(
        repo,
        StatusResult.success('Added: $backupRemoteName:$org'),
      );
    } else {
      builder.add(
        repo,
        StatusResult.error(await cmd.stderr),
      );
    }
  }

  @override
  Future<void> processNonGitDir(NonGitRepo dir, CommandMode mode) =>
      builder.add(dir);

  @override
  Future<int> afterProcess(CommandMode mode) {
    builder.printToConsole();
    return super.afterProcess(mode);
  }
}
