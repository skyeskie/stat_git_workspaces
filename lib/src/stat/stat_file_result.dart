// Ordinary:
// 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
// Rename/copy:
// 2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path><sep><origPath>
// Unmerged:
// u <XY> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>
// Untracked:
// ? <path>
// Ignored:
// ! path

// Initial purposes:
// ? -> untracked
// 1/2 : just count
// u : Not sure

// <XY> two-chars describing staged/unstaged in short format
// <sub> 4char submodule "N..." for no / "S<c><m><u>" if submodule
// <mH> octal file mode in HEAD
// <mI> octal file mode in index
// <hH> object name in HEAD
// <hI> object name in index
// <X><score> rename/copy score. Ex: "R100", "C75"
// <sep> if '-z' option, uses NUL (0x00). Otherwise tab (0x09)

import 'package:ansix/ansix.dart';

enum BasicGitFileStatus {
  untracked,
  modified,
  unmerged,
  unknown,
  ;

  const BasicGitFileStatus();

  factory BasicGitFileStatus.fromLine(String line) =>
      switch (line.isNullOrEmpty ? '' : line.substring(0, 1)) {
        '?' => BasicGitFileStatus.untracked,
        '1' => BasicGitFileStatus.modified,
        '2' => BasicGitFileStatus.modified,
        'u' => BasicGitFileStatus.unmerged,
        _ => BasicGitFileStatus.unknown,
      };
}

extension MapToCommonValues on Map<BasicGitFileStatus, int> {
  (int modified, int untracked, int unmerged) get asRecord => (
        this[BasicGitFileStatus.modified] ?? 0,
        this[BasicGitFileStatus.untracked] ?? 0,
        this[BasicGitFileStatus.unmerged] ?? 0,
      );
}

/*
enum GitFileStatus {
  unmodified(' ', AnsiColor.grey, displayAs: '='),
  modified('M', AnsiColor.yellow),
  typeChanged('T', AnsiColor.yellow),
  added('A', AnsiColor.aqua),
  deleted('D', AnsiColor.orange1),
  renamed('R', AnsiColor.greenYellow),
  copied('C', AnsiColor.aquamarine1),
  updatedUnmerged('U', AnsiColor.cyan1),
  unknown('?', AnsiColor.orangeRed1),
  ;

  factory GitFileStatus.fromSymbol(String? char) => values.firstWhere(
        (element) => element.symbol == char,
        orElse: () => GitFileStatus.unknown,
      );

  const GitFileStatus(this.symbol, this.color, {String? displayAs})
      : displaySymbol = displayAs ?? symbol;

  final String symbol;
  final String displaySymbol;
  final AnsiColor color;
}
*/
