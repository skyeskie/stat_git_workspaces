import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/git_remote.dart';
import 'package:stat_git_workspaces/src/core/table_builder.dart';

import '../core/dir_stat.dart';

enum StatHeader implements TableHeaderEnum {
  repoName('Repository'),
  branch('Branch'),
  backupRepo('Backup'),
  originRepo('Origin'),
  upstreamRepo('Upstream'),
  otherRemotes('Remotes'),
  ;

  const StatHeader(this.desc);

  @override
  final String desc;
}

class StatTableBuilder extends TableBuilder<StatHeader> {
  @override
  List<StatHeader> get enumCols => StatHeader.values;

  @override
  Future<AnsiText> addGitRow(StatHeader header, GitRepo gitRepo) async =>
      switch (header) {
        StatHeader.repoName => AnsiText(gitRepo.name),
        StatHeader.branch => AnsiText(await gitRepo.branch,
            foregroundColor: switch (await gitRepo.branch) {
              'mainline' => AnsiColor.greenYellow,
              'master' => AnsiColor.orange1,
              'main' => AnsiColor.greenYellow,
              'dev' => AnsiColor.green,
              _ => AnsiColor.cyan2,
            }),
        StatHeader.backupRepo => formatRemote(await gitRepo.backup),
        StatHeader.originRepo => formatRemote(await gitRepo.origin),
        StatHeader.upstreamRepo => formatRemote(
            await gitRepo.upstream,
            noRemoteColoring: AnsiColor.grey,
          ),
        StatHeader.otherRemotes => AnsiText(
            (await gitRepo.remoteNames)
                .where(
                  (element) => !['origin', 'nas', 'upstream'].contains(element),
                )
                .join(', '),
          ).replaceEmptyWith(blank),
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

extension BlankReplace on AnsiText {
  AnsiText replaceEmptyWith(AnsiText value) => text.isEmpty ? value : this;
}
