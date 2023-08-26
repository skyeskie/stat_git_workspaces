import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/git_remote.dart';

import 'repo_info.dart';

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
        StatHeader.gitStatus => getColoredBool(false),
        _ => blank,
      };

  AnsiText _addGit(StatHeader header, GitRepoInfo gitRepo) => switch (header) {
        StatHeader.repoName => AnsiText(gitRepo.name),
        StatHeader.gitStatus => getColoredBool(true),
        StatHeader.backupRepo => formatRemote(gitRepo.backup),
        StatHeader.originRepo => formatRemote(gitRepo.origin),
        StatHeader.upstreamRepo => formatRemote(gitRepo.upstream),
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

  static AnsiText formatRemote(GitRemote? remote) {
    if (remote == null) {
      return AnsiText(
        'x',
        foregroundColor: AnsiColor.red,
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
  gitStatus('Git'),
  backupRepo('Backup'),
  originRepo('Origin'),
  upstreamRepo('Upstream'),
  ;

  const StatHeader(this.desc);

  final String desc;
}
