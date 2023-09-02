part of 'dir_stat.dart';

class GitRepo extends DirStat {
  GitRepo({
    required this.root,
    this.mode = CommandMode.batch,
    required super.args,
    required super.globalArgs,
  }) : super.fromDirectory(root);

  final Directory root;
  final CommandMode mode;

  // ['status', '--porcelain=v2', '--show-stash', '--untracked-files=normal']

  @override
  String get name => path.basename(root.path);

  final remoteParse = RegExp(r'(\S+)\s+(\S+)\s+\((fetch|push)\)');

  Future<List<(String, String)>> get remoteNames => runGitCmd(
        ['remote', '-v'],
        runAlways: true,
        cache: true,
      ).results.then(
            (remotes) => remotes
                .map((remote) {
                  final matches = remoteParse.allMatches(remote);
                  if (matches.length != 1) return null;
                  final match = matches.single;
                  if (match.groupCount != 3) return null;
                  if (match.group(3) == 'push') return null;
                  return (match.group(1), match.group(2));
                })
                .whereType<(String, String)>()
                .toList(),
          );

  Future<String> get branch => runGitCmd(
        ['symbolic-ref', '--short', 'HEAD'],
        runAlways: true,
        cache: true,
      ).stdout.then(
            (output) => output.trim(),
          );

  Future<GitRemote?> get origin => getRemoteInfo(
        getArg('origin-remote-name'),
        sameBranch: true,
      );

  Future<GitRemote?> get backup => getRemoteInfo(
        getArg('backup-remote-name'),
        sameBranch: true,
      );

  Future<GitRemote?> get upstream =>
      getRemoteInfo(getArg('upstream-remote-name'));

  // General commands

  Future<GitRemote?> getRemoteInfo(
    String remoteName, {
    bool sameBranch = false,
  }) async {
    final remotes = await remoteNames;
    final remoteMatch = remotes.where(
      (element) => element.$1 == remoteName,
    );
    if (remoteMatch.isEmpty) return null;

    final branch = await this.branch;
    try {
      final (ahead, behind) = await getRemoteDiff(
        remoteName: remoteName,
        remoteBranch: sameBranch ? branch : 'HEAD',
        branch: branch,
      );

      return GitRemote(
        name: remoteName,
        uri: RepositoryUrl(remoteMatch.first.$2),
        branch: sameBranch ? branch : 'HEAD',
        ahead: ahead,
        behind: behind,
      );
    } catch (error) {
      // print(error.toString().cliError());
      return GitRemote.error(
        error: error.toString(),
        name: name,
        branch: branch,
        uri: RepositoryUrl(remoteMatch.first.$2),
      );
    }
  }

  final _abParse = RegExp(r'(\d+)\s+(\d+)');

  Future<(int ahead, int behind)> getRemoteDiff({
    required String remoteName,
    required String branch,
    String remoteBranch = 'HEAD',
  }) async {
    final head = path.joinAll(
      [root.path, '.git', 'refs', 'remotes', remoteName, remoteBranch],
    );

    if (!(await File(head).exists())) {
      return Future.error('No ref $remoteName/$remoteBranch');
    }

    final pre = const ['rev-list', '--count', '--left-right'];
    final aheadBehindCmd = runGitCmd(
      [...pre, '$branch...$remoteName/$remoteBranch', '--'],
      promptCommandName: 'branch-ahead',
      cache: true,
    );

    try {
      if (!await aheadBehindCmd.run()) {
        return Future.error(await aheadBehindCmd.stderr);
      }
    } catch (error) {
      return Future.error(error);
    }
    final cmdResult = await aheadBehindCmd.stdout;
    final matches = _abParse.matchAsPrefix(await aheadBehindCmd.stdout);

    if (matches == null || matches.groupCount != 2) {
      return Future.error('Error parsing "$cmdResult"');
    }

    return (
      int.parse(matches.group(1)!),
      int.parse(matches.group(2)!),
    );
  }

  final _cache = <String, GitCommand>{};

  GitCommand runGitCmd(
    List<String> command, {
    bool runAlways = false,
    String? promptCommandName,
    bool cache = false,
  }) {
    final subcmd = command.join(' ');
    if (cache) {
      final cacheVal = _cache[subcmd];
      if (cacheVal != null) return cacheVal;
    }

    final cmd = GitCommand(
      command,
      workingDirectory: root.path,
      promptCommandName: promptCommandName,
      mode: mode,
      runAlways: runAlways,
      repoName: name,
    );
    if (cache) _cache[subcmd] = cmd;
    return cmd;
  }
}
