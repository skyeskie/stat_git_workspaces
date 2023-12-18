import 'dart:async';

import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/dir_stat.dart';
import 'package:stat_git_workspaces/src/core/multi_command.dart';

class GitInitCommand extends MultiCommand {
  @override
  String get description => 'Initialize Git repositories where needed';

  @override
  String get describeInitAction => 'Initializing repositories';

  @override
  String get name => 'init';

  @override
  Future<void> processGitRepo(GitRepo repo, CommandMode mode) {
    // TODO: implement processGitRepo
    throw UnimplementedError();
  }

  @override
  Future<void> processNonGitDir(NonGitRepo dir, CommandMode mode) {
    // TODO: implement processNonGitDir
    throw UnimplementedError();
  }

  @override
  // TODO: implement enumCols
  List<TableHeaderEnum> get enumCols => throw UnimplementedError();

  @override
  FutureOr<AnsiText> formatGitRepo(
      {required TableHeaderEnum header, required GitRepo gitRepo, results}) {
    // TODO: implement formatGitRepo
    throw UnimplementedError();
  }
}
