import 'dart:async';

import 'package:stat_git_workspaces/src/core/repo_info.dart';

import '../core/multi_command.dart';
import 'stat_table_builder.dart';

class StatCommand extends MultiCommand {
  StatCommand() : super();

  final builder = StatTableBuilder();

  @override
  String get description => 'Show information of all workspaces';

  @override
  String get name => command;

  static const String command = 'stat';

  @override
  Future<void> processGitRepo(GitRepoInfo repoInfo) async =>
      builder.add(repoInfo);

  @override
  Future<void> processNonGitDir(NonGitRepo dir) async => builder.add(dir);

  @override
  FutureOr<int>? run() async {
    await super.run();

    builder.printToConsole();
    return 0;
  }
}
