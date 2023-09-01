import 'package:args/args.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:stat_git_workspaces/cfg.dart';
import 'package:stat_git_workspaces/src/backup/backup_cmd.dart';
import 'package:stat_git_workspaces/src/remote/git_fetch.dart';
import 'package:stat_git_workspaces/src/stat/stat_command.dart';

class CliMain extends CompletionCommandRunner<int> {
  CliMain(super.executableName, super.description) {
    final cfg = Config.get();
    argParser.addOption(
      'backup-remote-name',
      aliases: ['remote'],
      defaultsTo: cfg.backupRemoteName,
    );
    argParser.addOption(
      'origin-remote-name',
      aliases: ['origin'],
      defaultsTo: cfg.originRemoteName,
    );
    argParser.addOption(
      'upstream-remote-name',
      aliases: ['upstream'],
      defaultsTo: cfg.upstreamRemoteName,
    );
    argParser.addFlag('verbose', abbr: 'v', help: 'Show debug output');

    addCommand(StatCommand());
    addCommand(BackupCmd());
    addCommand(GitFetch());
  }

  @override
  ArgResults parse(Iterable<String> args) {
    if (args.isEmpty) {
      return super.parse([StatCommand.command]);
    }
    return super.parse(args);
  }
}
