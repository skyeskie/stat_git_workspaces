import 'dart:async';

import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/stat/stat_file_result.dart';
import 'package:stat_git_workspaces/src/util/cli_printer.dart';
import 'package:stat_git_workspaces/src/util/repository_url.dart';

import '../core/git_remote.dart';
import '../core/multi_command.dart';
import '../remote/remote_multi_cmd.dart';

typedef RemoteInfo = Map<BasicGitFileStatus, int>;

class StatCommand extends RemoteMultiCmd<RemoteInfo> {
  StatCommand() : super(addBatchOption: false);

  @override
  String get description => 'Show information of all workspaces';

  @override
  String get describeInitAction => 'Scanning repositories';

  @override
  String get name => command;

  static const String command = 'stat';

  @override
  FutureOr<AnsiText> formatBranchColumn(
    String branchName,
    RemoteInfo? results,
  ) async {
    final branchText = await super.formatBranchColumn(branchName, results);
    if (results == null) return branchText;

    final prefix = switch (results.asRecord) {
      (_, _, > 0) => '## '.withForegroundColor(AnsiColor.red),
      (> 0, > 0, _) => 'MU '.withForegroundColor(AnsiColor.yellow),
      (> 0, _, _) => 'M  '.withForegroundColor(AnsiColor.yellow2),
      (_, > 0, _) => ' U '.withForegroundColor(AnsiColor.yellow3),
      (_, _, _) => '  '.withForegroundColor(AnsiColor.green),
    };

    return AnsiText(
      '$prefix${branchText.formattedText}',
    );
  }

  @override
  Future<AnsiText> formatRemoteColumn(
    GitRemote? remote,
    void results,
  ) async {
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
  Future<RemoteInfo> processGitRepo(repo, mode) async {
    final cmd = repo.runGitCmd(
      ['status', '--porcelain=v2'],
      promptCommandName: 'status',
      runAlways: true,
    );

    final types = <BasicGitFileStatus, int>{
      BasicGitFileStatus.untracked: 0,
      BasicGitFileStatus.modified: 0,
      BasicGitFileStatus.unmerged: 0,
    };
    for (final result in await cmd.results) {
      final status = BasicGitFileStatus.fromLine(result);
      types[status] = (types[status] ?? 0) + 1;
    }

    return types;
  }

  @override
  Future<int> afterProcess(CommandMode mode) {
    if (mode.execute) {
      return super.afterProcess(mode);
    } else {
      AnsiX.printStyled(
        'Does not support non-execute modes'.cliError(),
        textStyle: const AnsiTextStyle(),
      );
      return Future.value(1);
    }
  }
}
