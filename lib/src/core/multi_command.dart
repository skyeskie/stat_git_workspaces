import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:stat_git_workspaces/src/core/repo_info.dart';

import '../../cfg.dart';
import 'git_repo.dart';

abstract class MultiCommand extends Command<int> {
  MultiCommand() {
    argParser.addOption(
      'workspace',
      abbr: 'w',
      aliases: ['ws', 'root', 'r'],
      defaultsTo: config.getWorkspaceDir().path,
      help: 'Workspace root containing Git projects',
      valueHelp: '~/ws/',
    );

    argParser.addFlag('batch',
        abbr: 'b', defaultsTo: false, help: 'Automatically run commands');

    argParser.addFlag('dry-run',
        abbr: 'd',
        defaultsTo: false,
        help: 'Print print commands instead of running. Implies -b');
  }

  final config = Config.get();

  Future<void> processGitRepo(GitRepoInfo repoInfo);

  Future<void> processNonGitDir(NonGitRepo dir);

  @override
  FutureOr<int>? run() async {
    final ws = Directory(argResults!['workspace']);
    final lsAll = await ws.list().toList();
    final projects = lsAll.whereType<Directory>().toList(growable: false);
    projects.sort((a, b) => a.path.compareTo(b.path));

    for (final project in projects) {
      final projectInfo = GitRepo(root: project);
      if (await projectInfo.checkIfGitDir()) {
        await processGitRepo(await projectInfo.getInfo() as GitRepoInfo);
      } else {
        processNonGitDir(NonGitRepo(name: projectInfo.getRepoName()));
      }
    }

    return 0;
  }
}
