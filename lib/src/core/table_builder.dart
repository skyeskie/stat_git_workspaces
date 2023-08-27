import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/repo_info.dart';

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

  void add(DirStat repo) {
    for (final header in enumCols) {
      _addField(
        header,
        switch (repo) {
          (NonGitRepo dir) => _addNonGit(header, dir.name),
          (GitRepoInfo gitRepo) => addGitRow(header, gitRepo),
        },
      );
    }
  }

  AnsiText _addNonGit(T header, String name) {
    if (header == _table.keys.first) {
      return AnsiText(name);
    }
    if (header == _table.keys.skip(1).first) {
      return AnsiText(
        'Not Git',
        foregroundColor: AnsiColor.red,
      );
    }
    return blank;
  }

  AnsiText addGitRow(T header, GitRepoInfo gitRepo);

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
