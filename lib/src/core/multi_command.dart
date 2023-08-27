import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:stat_git_workspaces/src/core/repo_info.dart';

import '../../cfg.dart';
import 'git_repo.dart';

abstract class MultiCommand extends Command<int> {
  MultiCommand({
    bool addBatchOption = true,
    bool addDryRunOption = true,
  }) {
    argParser.addOption(
      'workspace',
      abbr: 'w',
      aliases: ['ws', 'root', 'r'],
      defaultsTo: config.getWorkspaceDir().path,
      help: 'Workspace root containing Git projects',
      valueHelp: '~/ws/',
    );

    argParser.addFlag(
      'batch',
      abbr: 'b',
      defaultsTo: !addBatchOption,
      help: 'Automatically run commands',
      hide: addBatchOption,
    );

    argParser.addFlag(
      'dry-run',
      abbr: 'd',
      defaultsTo: false,
      help: 'Print print commands instead of running. Implies -b',
      hide: addDryRunOption,
    );
  }

  CommandMode determineCommandMode() {
    if (argResults?['dry-run']) return CommandMode.printCommands;
    bool? batchFlag = argResults?['batch'];
    return switch (batchFlag) {
      (true) => CommandMode.batch,
      (false) => CommandMode.confirmEach,
      (null) => CommandMode.noBatchOption,
    };
  }

  final config = Config.get();

  Future<void> processGitRepo(GitRepoInfo repoInfo, CommandMode mode);

  Future<void> processNonGitDir(NonGitRepo dir, CommandMode mode);

  Future<int> afterProcess(CommandMode mode) async => 0;

  @override
  FutureOr<int>? run() async {
    final ws = Directory(argResults!['workspace']);
    final lsAll = await ws.list().toList();
    final projects = lsAll.whereType<Directory>().toList(growable: false);
    projects.sort((a, b) => a.path.compareTo(b.path));

    final mode = determineCommandMode();

    for (final project in projects) {
      final projectInfo = GitRepo(root: project);
      if (await projectInfo.checkIfGitDir()) {
        await processGitRepo(await projectInfo.getInfo() as GitRepoInfo, mode);
      } else {
        processNonGitDir(NonGitRepo(name: projectInfo.getRepoName()), mode);
      }
    }

    return afterProcess(mode);
  }
}

enum CommandMode {
  batch(confirm: false),
  confirmEach(confirm: true),
  printCommands(execute: false, confirm: false),
  noBatchOption(execute: true, confirm: false),
  ;

  const CommandMode({this.execute = true, required this.confirm});

  final bool execute;
  final bool confirm;
}
