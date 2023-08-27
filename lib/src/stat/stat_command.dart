import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:stat_git_workspaces/cfg.dart';

import '../core/git_repo.dart';
import 'stat_table_builder.dart';

class StatCommand extends Command<int> {
  StatCommand() {
    final config = Config.get();
    argParser.addOption(
      'workspace',
      abbr: 'w',
      aliases: ['ws', 'root', 'r'],
      defaultsTo: config.getWorkspaceDir().path,
      help: 'Workspace root containing Git projects',
      valueHelp: '~/ws/',
    );
  }

  @override
  String get description => 'Show information of all workspaces';

  @override
  String get name => command;

  static const String command = 'stat';

  @override
  FutureOr<int>? run() async {
    final ws = Directory(argResults!['workspace']);
    final projects = await ws.list().toList();
    projects.retainWhere((element) => element is Directory);
    projects.sort((a, b) => a.path.compareTo(b.path));

    final builder = StatTableBuilder();
    for (final project in projects) {
      if (project is Directory) {
        final projectInfo = GitRepo(root: project);
        builder.add(await projectInfo.getInfo());
      }
    }
    builder.printToConsole();
    return 0;
  }
}
