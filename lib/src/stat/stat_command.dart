import 'dart:async';

import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/util/cli_printer.dart';
import 'package:stat_git_workspaces/src/util/repository_url.dart';

import '../core/git_remote.dart';
import '../core/multi_command.dart';
import 'remote_table_builder.dart';

class StatCommand extends MultiCommand {
  StatCommand() : super(addBatchOption: false);

  final builder = RemoteTableBuilder(
    formatRemote: formatRemoteStatus,
  );

  @override
  String get description => 'Show information of all workspaces';

  @override
  String get describeInitAction => 'Scanning repositories';

  @override
  String get name => command;

  static const String command = 'stat';

  static AnsiText formatRemoteStatus(
    GitRemote? remote,
    void results, {
    AnsiColor noRemoteColoring = RemoteTableBuilder.defaultNoRemoteColoring,
  }) {
    final errorOut = RemoteTableBuilder.formatRemoteErrorConditions(
      remote,
      noRemoteColoring: noRemoteColoring,
    );
    if (errorOut != null) return errorOut;
    assert(remote != null); //Handled in errorOut

    final remoteDisplay = [remote!.uri.organization, remote.branch].join(':');

    return AnsiText(
      [
        remoteDisplay,
        if (remote.behind > 0) ' ⇣${remote.behind}',
        if (remote.ahead > 0) ' ⇡${remote.ahead}',
      ].join(),
      foregroundColor: switch ((remote.behind, remote.ahead)) {
        (== 0, == 0) => AnsiColor.green,
        (> 0, > 0) => AnsiColor.orangeRed1,
        (> 0, _) => AnsiColor.yellow,
        (_, > 0) => AnsiColor.cyan1,
        _ => AnsiColor.red2,
      },
      // alignment: AnsiTextAlignment.center,
    );
  }

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
        'Does not support non-execute modes'.cliError(),
        textStyle: const AnsiTextStyle(),
      );
      return Future.value(1);
    }
    return super.afterProcess(mode);
  }
}
