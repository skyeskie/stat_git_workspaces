import 'dart:async';

import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/dir_stat.dart';
import 'package:stat_git_workspaces/src/core/multi_command.dart';
import 'package:stat_git_workspaces/src/remote/fetch_branch_result.dart';
import 'package:stat_git_workspaces/src/remote/remote_multi_cmd.dart';
import 'package:stat_git_workspaces/src/util/cli_printer.dart';

import '../core/git_remote.dart';

typedef RemoteInfo = Map<String, List<String>>;

class GitFetch extends RemoteMultiCmd<RemoteInfo> {
  GitFetch() {
    argParser.addFlag('all', defaultsTo: false);
  }

  @override
  String get name => 'fetch';

  @override
  String get describeInitAction => 'Fetching repositories';

  @override
  String get description => 'Run fetch on remotes';

  @override
  Future<AnsiText> formatRemoteColumn(
      GitRemote remote, Map<String, List<String>>? results) async {
    final resultsForRemote = results?[remote.name];

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
  Future<RemoteInfo> processGitRepo(GitRepo repo, CommandMode mode) async {
    // CliPrinter.debug('process repo: ${repo.name}');
    final remoteConfigs = await repo.remoteNames;
    // Default is to use [origin, backup, upstream] repositories
    final remotesResults = <String, List<String>>{
      globalResults!['backup-remote-name']: [],
      globalResults!['origin-remote-name']: [],
      globalResults!['upstream-remote-name']: [],
    };
    Set<String> remotesToCheck = Set.of(remoteConfigs.map((e) => e.$1));
    if (!argResults!['all']) {
      final mainRemotes = remotesResults.keys.toSet();
      remotesToCheck.removeWhere((element) => !mainRemotes.contains(element));
    }

    for (final remoteName in remotesToCheck) {
      remotesResults[remoteName] = await processSingleRemote(repo, remoteName);
    }

    return remotesResults;

    // Will run all remotes
    // scan for "error: could not fetch <name>" on error
    // Successful will be "refs/remotes/<name/*
  }

  Future<List<String>> processSingleRemote(
    GitRepo repo,
    String remoteName,
  ) async {
    var cmd = ['fetch', '--verbose', '--porcelain', remoteName];
    await CliPrinter.debug('> git ${cmd.join(" ")}');
    final results = repo.runGitCmd(cmd, promptCommandName: 'fetch');

    final branchOutputs = <String>[];
    for (final line in await results.results) {
      if (line.isEmpty) continue;
      final branchResult = RemoteBranchFetchResult.parse(line);
      branchOutputs.add(
        branchResult.status.colorDisplay,
      );
    }

    if (!(await results.run())) {
      final error = await results.stderr;
      await CliPrinter.info(await results.stdout);
      await CliPrinter.error(error);
      if (error.contains('Connection refused')) {
        return ['Connection refused'.cliError()];
      }
      if (error.contains('No route to host')) {
        return ['Network error'.cliError()];
      }
      if (error.contains('Permission denied (publickey)')) {
        return ['Permission denied (publickey)'.cliError()];
      }
    }

    return branchOutputs;
  }
}
