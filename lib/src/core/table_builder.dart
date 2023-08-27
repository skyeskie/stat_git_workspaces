import 'dart:async';

import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/dir_stat.dart';

abstract class TableBuilder<T extends TableHeaderEnum> {
  List<T> get enumCols;

  final blank = AnsiText(
    '-',
    foregroundColor: AnsiColor.grey27,
    alignment: AnsiTextAlignment.center,
  );

  late final Map<String, List<AnsiText>> _table;

  TableBuilder() {
    _table = Map.fromEntries(enumCols.map(
      (header) => MapEntry(header.desc, <AnsiText>[]),
    ));
  }

  void _addField(T header, AnsiText value) {
    _table[header.desc]!.add(value);
  }

  Future<void> add(DirStat repo) async {
    for (final header in enumCols) {
      _addField(
        header,
        switch (repo) {
          (NonGitRepo dir) => _addNonGit(header, dir.name),
          (GitRepo gitRepo) => await addGitRow(header, gitRepo),
        },
      );
    }
  }

  AnsiText _addNonGit(T header, String name) {
    if (header.desc == _table.keys.first) {
      return AnsiText(name);
    }
    if (header.desc == _table.keys.skip(1).first) {
      return AnsiText(
        'No Git Repo',
        foregroundColor: AnsiColor.red,
      );
    }
    return blank;
  }

  FutureOr<AnsiText> addGitRow(T header, GitRepo gitRepo);

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
}

abstract class TableHeaderEnum {
  String get desc;
}
