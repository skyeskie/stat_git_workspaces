import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart';
import 'package:path/path.dart';
import 'package:stat_git_workspaces/src/core/dir_stat.dart';

import '../../cfg.dart';

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

  Future<void> processGitRepo(GitRepo repo, CommandMode mode);

  Future<void> processNonGitDir(NonGitRepo dir, CommandMode mode);

  Future<int> afterProcess(CommandMode mode) async => 0;

  @override
  FutureOr<int>? run() async {
    final ws = Directory(argResults!['workspace']);
    final lsAll = await ws.list().toList();
    final projects = lsAll.whereType<Directory>().toList(growable: false);
    projects.sort((a, b) => a.path.compareTo(b.path));

    final mode = determineCommandMode();

    final dirs = projects.map((e) => basename(e.path)).toList(growable: false);
    final dirPad = dirs.map((e) => e.length).reduce(max);
    final numProjects = projects.length;

    final progress = Progress(
      length: numProjects,
      size: 0.5,
      leftPrompt: (i) => i == projects.length
          ? 'Finishing'
          : 'Pushing ${dirs[i].padRight(dirPad)}: ',
      rightPrompt: (i) => '${i.toString().padLeft(3)} / $numProjects',
    ).interact();

    for (final project in projects) {
      progress.increase(1);
      if (await DirStat.checkIfGitDir(project.path)) {
        await processGitRepo(
          GitRepo(
            root: project,
            args: argResults!,
            globalArgs: globalResults,
            mode: mode,
          ),
          mode,
        );
      } else {
        await processNonGitDir(
          NonGitRepo(
            name: DirStat.getNameFromDir(project),
            args: argResults!,
            globalArgs: globalResults,
          ),
          mode,
        );
      }
    }

    progress.done();

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
