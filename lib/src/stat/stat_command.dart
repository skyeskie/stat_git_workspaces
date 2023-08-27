import 'dart:async';

import 'package:ansix/ansix.dart';

import '../core/multi_command.dart';
import 'stat_table_builder.dart';

class StatCommand extends MultiCommand {
  StatCommand() : super(addBatchOption: false);

  final builder = StatTableBuilder();

  @override
  String get description => 'Show information of all workspaces';

  @override
  String get name => command;

  static const String command = 'stat';

  @override
  Future<void> processGitRepo(repo, mode) => builder.add(repo);

  @override
  Future<void> processNonGitDir(dir, mode) => builder.add(dir);

  @override
  Future<int> afterProcess(CommandMode mode) {
    if (mode.execute) {
      builder.printToConsole();
    } else {
      AnsiX.printStyled(
        'Does not support non-execute modes'.withForegroundColor(AnsiColor.red),
        textStyle: const AnsiTextStyle(),
      );
      return Future.value(1);
    }
    return super.afterProcess(mode);
  }
}
