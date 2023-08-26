import 'package:ansix/ansix.dart';

import 'repo_info.dart';

class StatTableBuilder {
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
      };

  AnsiText _addGit(StatHeader header, GitRepoInfo gitRepo) => switch (header) {
        StatHeader.repoName => AnsiText(gitRepo.name),
        StatHeader.gitStatus => getColoredBool(true),
      };

  AnsiTable build() => AnsiTable.fromMap(_table);

  void printToConsole() {
    AnsiX.printStyled(build(), textStyle: const AnsiTextStyle());
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
  gitStatus('Git');

  const StatHeader(this.desc);

  final String desc;
}
