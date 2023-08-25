import 'dart:io';

import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/cfg.dart';
import 'package:stat_git_workspaces/src/git_repo.dart';

typedef RepoViewModel = (String repoName, bool isGitRepo);

class Workspace {
  Workspace([Directory? dir]) {
    this.dir = dir ?? cfg.getWorkspaceDir();
  }

  final cfg = Config.get();
  late final Directory dir;

  Future<void> displayListing() async {
    final projects = dir.list();
    final tableData = <RepoViewModel>[];
    await for (final project in projects) {
      if (project is Directory) {
        final projectInfo = GitRepo(root: project);
        tableData.add(await present(projectInfo));
      }
    }

    tableData.sort((a, b) => a.$1.compareTo(b.$1));

    final table = remap(tableData);
    AnsiX.printStyled(table, textStyle: const AnsiTextStyle());
  }

  Future<RepoViewModel> present(GitRepo repo) async {
    final repoName = repo.getRepoName();
    final isGitRepo = await repo.checkIfGitDir();
    return (repoName, isGitRepo);
  }

  AnsiText getColoredBool(bool value) {
    if (value) {
      return AnsiText('Yes', foregroundColor: AnsiColor.green);
    } else {
      return AnsiText('No', foregroundColor: AnsiColor.red);
    }
  }

  AnsiTable remap(List<RepoViewModel> data) {
    final tableMap = <String, List<AnsiText>>{
      'Repository': [],
      'Git': [],
    };
    for (final RepoViewModel item in data) {
      tableMap['Repository']!.add(AnsiText(item.$1));
      tableMap['Git']!.add(getColoredBool(item.$2));
    }
    return AnsiTable.fromMap(
      tableMap,
    );
  }
}
