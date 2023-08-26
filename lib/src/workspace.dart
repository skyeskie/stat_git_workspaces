import 'dart:io';

import 'package:stat_git_workspaces/cfg.dart';
import 'package:stat_git_workspaces/src/git_repo.dart';
import 'package:stat_git_workspaces/src/stat_table_builder.dart';

typedef RepoViewModel = (String repoName, bool isGitRepo);

class Workspace {
  Workspace([Directory? dir]) {
    this.dir = dir ?? cfg.getWorkspaceDir();
  }

  final cfg = Config.get();
  late final Directory dir;

  Future<void> displayListing() async {
    final projects = await dir.list().toList();
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
  }
}
