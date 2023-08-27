part of 'dir_stat.dart';

class GitRepo extends DirStat {
  GitRepo({
    required this.root,
    this.mode = CommandMode.batch,
    required super.args,
  }) : super.fromDirectory(root);

  final Directory root;
  final CommandMode mode;

  // ['status', '--porcelain=v2', '--show-stash', '--untracked-files=normal']

  @override
  String get name => path.basename(root.path);

  Future<List<String>> get remoteNames => runGitCmd(
        ['remote'],
        runAlways: true,
        cache: true,
      );

  Future<String> get branch => runGitCmdSingle(
        ['symbolic-ref', '--short', 'HEAD'],
        runAlways: true,
        cache: true,
      );

  Future<GitRemote?> get origin => getRemoteInfo(args['origin']);

  Future<GitRemote?> get backup => getRemoteInfo(args['backup']);

  Future<GitRemote?> get upstream => getRemoteInfo(args['upstream']);

  // General commands

  Future<GitRemote?> getRemoteInfo(String remoteName) async {
    final remotes = await remoteNames;
    if (!remotes.contains(remoteName)) return null;
    return GitRemote(name: remoteName, branch: 'TODO');
  }

  // TODO: Move main git commands to separate object?

  final _cache = <String, List<String>>{};

  Future<List<String>> runGitCmd(
    List<String> command, {
    bool runAlways = false,
    String? promptCommandName,
    bool cache = false,
  }) async {
    final subcmd = command.join(' ');
    if (cache) {
      final cacheVal = _cache[subcmd];
      if (cacheVal != null) return cacheVal;
    }
    if (mode == CommandMode.printCommands) {
      print('git $subcmd');
    }
    promptCommandName ??= command.first;
    bool execute = runAlways || mode.execute;
    if (!runAlways || mode.confirm) {
      try {
        execute = Confirm(
          prompt: 'Run $promptCommandName on $name?',
          defaultValue: true, // this is optional
          waitForNewLine: true, // optional and will be false by default
        ).interact();
      } catch (e) {
        // Interrupting interact prompt could mess up console
        reset();
        rethrow;
      }
    }
    if (execute) {
      final result = DirStat.runGitCmd(
        command,
        workingDirectory: root.path,
      );
      if (cache) _cache[subcmd] = await result;
      return result;
    }
    return Future.value(['Dry-run']);
  }

  Future<String> runGitCmdSingle(
    List<String> command, {
    bool runAlways = false,
    String? promptCommandName,
    bool cache = false,
  }) =>
      runGitCmd(
        command,
        runAlways: runAlways,
        promptCommandName: promptCommandName,
        cache: cache,
      ).then(
        (value) => value.single.trim(),
      );
}
