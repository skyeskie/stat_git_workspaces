import 'package:ansix/ansix.dart';

class RemoteBranchFetchResult {
  static final regexPorcelainV2 = RegExp(
    r'(.) ([a-f0-9]+) ([a-f0-9]+) refs/remotes/([^/]+)/([^\n]+)',
  );

  RemoteBranchFetchResult.parse(String line) {
    final result = regexPorcelainV2.matchAsPrefix(line);
    if (result == null || result.groupCount != 5) {
      throw ArgumentError.value(line, 'line');
    }

    status = FetchStatus.fromSymbol(result.group(1));
    from = result.group(2)!;
    to = result.group(3)!;
    remoteName = result.group(4)!;
    branchName = result.group(5)!;
  }

  late final FetchStatus status;
  late final String from;
  late final String to;
  late final String remoteName;
  late final String branchName;
}

enum FetchStatus {
  noChange('=', AnsiColor.green),
  fastForward(' ', AnsiColor.greenYellow, displayAs: ''),
  tag('t', AnsiColor.green),
  newFetch('*', AnsiColor.cyan1),
  forced('+', AnsiColor.yellow),
  pruned('-', AnsiColor.orange1),
  rejected('!', AnsiColor.red),
  unknown('?', AnsiColor.orangeRed1),
  ;

  factory FetchStatus.fromSymbol(String? char) => values.firstWhere(
        (element) => element.symbol == char,
        orElse: () => FetchStatus.unknown,
      );

  const FetchStatus(this.symbol, this.color, {String? displayAs})
      : displaySymbol = displayAs ?? symbol;

  final String symbol;
  final String displaySymbol;
  final AnsiColor color;

  String get colorDisplay => displaySymbol.withForegroundColor(color);
}
