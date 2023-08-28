import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/dir_stat.dart';
import 'package:stat_git_workspaces/src/core/multi_command.dart';
import 'package:stat_git_workspaces/src/setup/status_table_builder.dart';

class BackupInit extends MultiCommand {
  BackupInit() {
    argParser.addOption(
      'user',
      abbr: 'u',
      defaultsTo: config.user,
    );
  }

  final builder = StatusTableBuilder();

  @override
  String get description => 'Create backup remote for repositories missing one';

  @override
  String get name => 'init';

  static const statusExisting = StatusResult(
    description: 'Existing',
    color: AnsiColor.grey,
  );

  @override
  Future<void> processGitRepo(GitRepo repo, CommandMode mode) async {
    if (await repo.backup != null) return builder.add(repo, statusExisting);
    return builder.add(repo, StatusResult.error());
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
