import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/git_remote.dart';
import 'package:stat_git_workspaces/src/core/table_builder.dart';

import '../core/repo_info.dart';

enum StatHeader implements TableHeaderEnum {
  repoName('Repository'),
  branch('Branch'),
  backupRepo('Backup'),
  originRepo('Origin'),
  upstreamRepo('Upstream'),
  ;

  const StatHeader(this.desc);

  @override
  final String desc;
}

class StatTableBuilder extends TableBuilder<StatHeader> {
  @override
  List<StatHeader> get enumCols => StatHeader.values;

  @override
  AnsiText addGitRow(StatHeader header, GitRepoInfo gitRepo) =>
      switch (header) {
        StatHeader.repoName => AnsiText(gitRepo.name),
        StatHeader.branch => AnsiText(gitRepo.branch,
            foregroundColor: switch (gitRepo.branch) {
              'mainline' => AnsiColor.greenYellow,
              'master' => AnsiColor.orange1,
              'main' => AnsiColor.greenYellow,
              'dev' => AnsiColor.green,
              _ => AnsiColor.cyan2,
            }),
        StatHeader.backupRepo => formatRemote(gitRepo.backup),
        StatHeader.originRepo => formatRemote(gitRepo.origin),
        StatHeader.upstreamRepo => formatRemote(
            gitRepo.upstream,
            noRemoteColoring: AnsiColor.grey,
          ),
      };

  static AnsiText formatRemote(
    GitRemote? remote, {
    AnsiColor noRemoteColoring = AnsiColor.red,
  }) {
    if (remote == null) {
      return AnsiText(
        'x',
        foregroundColor: noRemoteColoring,
        alignment: AnsiTextAlignment.center,
      );
    }

    if (remote.isSync) {
      return AnsiText(
        remote.name,
        foregroundColor: AnsiColor.green,
        alignment: AnsiTextAlignment.center,
      );
    }

    return AnsiText(
      '${remote.behind} | ${remote.ahead}',
      foregroundColor: AnsiColor.orange1,
      alignment: AnsiTextAlignment.center,
    );
  }
}
