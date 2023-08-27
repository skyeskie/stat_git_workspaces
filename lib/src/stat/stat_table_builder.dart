import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/git_remote.dart';

import '../core/repo_info.dart';

class StatTableBuilder {
  static final blank = AnsiText(
    '-',
    foregroundColor: AnsiColor.grey27,
    alignment: AnsiTextAlignment.center,
  );

  final Map<String, List<AnsiText>> _table = Map.fromEntries(
    StatHeader.values.map(
      (header) => MapEntry(header.desc, <AnsiText>[]),
    ),
  );

  void _addField(StatHeader header, AnsiText value) {
    _table[header.desc]!.add(value);
  }

  void add(DirStat repo) {
    for (final header in StatHeader.values) {
      _addField(
        header,
        switch (repo) {
          (NonGitRepo dir) => _addNonGit(header, dir.name),
          (GitRepoInfo gitRepo) => _addGit(header, gitRepo),
        },
      );
    }
  }

  AnsiText _addNonGit(StatHeader header, String name) => switch (header) {
        StatHeader.repoName => AnsiText(name),
        StatHeader.branch => AnsiText(
            'Not Git',
            foregroundColor: AnsiColor.red,
          ),
        _ => blank,
      };

  AnsiText _addGit(StatHeader header, GitRepoInfo gitRepo) => switch (header) {
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

  AnsiTable build() => AnsiTable.fromMap(
        _table,
        headerTextTheme: AnsiTextTheme(
          style: AnsiTextStyle(
            bold: true,
          ),
          foregroundColor: AnsiColor.cyan1,
        ),
        border: AnsiBorder(type: AnsiBorderType.header),
      );

  void printToConsole() {
    AnsiX.printStyled(build(), textStyle: const AnsiTextStyle());
  }

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

  static AnsiText getColoredBool(bool value) {
    if (value) {
      return AnsiText('Yes', foregroundColor: AnsiColor.green);
    } else {
      return AnsiText('No', foregroundColor: AnsiColor.red);
    }
  }
}

enum StatHeader {
  repoName('Repository'),
  branch('Branch'),
  backupRepo('Backup'),
  originRepo('Origin'),
  upstreamRepo('Upstream'),
  ;

  const StatHeader(this.desc);

  final String desc;
}
