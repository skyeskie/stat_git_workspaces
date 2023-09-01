import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/dir_stat.dart';
import 'package:stat_git_workspaces/src/core/multi_command.dart';
import 'package:stat_git_workspaces/src/remote/fetch_branch_result.dart';
import 'package:stat_git_workspaces/src/stat/remote_table_builder.dart';
import 'package:stat_git_workspaces/src/util/cli_printer.dart';

import '../core/git_remote.dart';

class GitFetch extends MultiCommand {
  GitFetch() {
    argParser.addFlag('all', defaultsTo: false);
  }

  final builder = RemoteTableBuilder<Map<String, List<String>>>(
    formatRemote: formatRemoteFetchResults,
  );

  static AnsiText formatRemoteFetchResults(
    GitRemote? remote,
    Map<String, List<String>>? results, {
    AnsiColor noRemoteColoring = RemoteTableBuilder.defaultNoRemoteColoring,
  }) {
    final errorOut = RemoteTableBuilder.formatRemoteErrorConditions(
      remote,
      noRemoteColoring: noRemoteColoring,
    );
    if (errorOut != null) return errorOut;
    assert(remote != null); //Handled in errorOut

    final resultsForRemote = results?[remote!.name];

    if (resultsForRemote == null || resultsForRemote.isEmpty) {
      return AnsiText(
        'No branches',
        foregroundColor: AnsiColor.orangeRed1,
        alignment: AnsiTextAlignment.center,
      );
    }

    return AnsiText(
      resultsForRemote.join(''),
      alignment: AnsiTextAlignment.center,
    );
  }

  @override
  String get description => 'Run fetch on remotes';

  @override
  String get name => 'fetch';

  @override
  Future<void> processGitRepo(GitRepo repo, CommandMode mode) async {
    // CliPrinter.debug('process repo: ${repo.name}');
    final remoteConfigs = await repo.remoteNames;
    var cmd = ['fetch', '--verbose', '--porcelain'];
    // Default is to use [origin, backup, upstream] repositories
    final remotesResults = <String, List<String>>{
      globalResults!['backup-remote-name']: [],
      globalResults!['origin-remote-name']: [],
      globalResults!['upstream-remote-name']: [],
    };
    if (argResults!['all']) {
      cmd.add('--all');
    } else {
      cmd.add('--multiple');
      final remotesToCheck = Set.of(
        remotesResults.keys,
      ).intersection(
        remoteConfigs.map((e) => e.$1).toSet(),
      );
      cmd.addAll(remotesToCheck);
    }
    // CliPrinter.debug('> git ${cmd.join(" ")}');
    final results = repo.runGitCmd(cmd, promptCommandName: 'fetch');

    for (final line in await results.results) {
      if (line.isEmpty) continue;
      final branchResult = RemoteBranchFetchResult.parse(line);
      remotesResults[branchResult.remoteName]?.add(
        branchResult.status.colorDisplay,
      );
      // CliPrinter.info(await results.stdout);
    }

    if (!(await results.run())) {
      final error = (await results.stderr).split('\n');
      final shortErrorMatch = RegExp(r'^error: ');
      for (final errorLine in error) {
        if (shortErrorMatch.hasMatch(errorLine)) {
          final remote = errorLine.split(' ').last;
          remotesResults[remote]?.add(errorLine.replaceFirst('error: ', ''));
        }
      }

      CliPrinter.error(error.join('\n'));
    }

    builder.add(repo, remotesResults);

    // Will run all remotes
    // scan for "error: could not fetch <name>" on error
    // Successful will be "refs/remotes/<name/*
  }

  @override
  Future<void> processNonGitDir(
    NonGitRepo dir,
    CommandMode mode,
  ) =>
      builder.add(dir);

  @override
  Future<int> afterProcess(CommandMode mode) {
    builder.printToConsole();
    return super.afterProcess(mode);
  }
}
