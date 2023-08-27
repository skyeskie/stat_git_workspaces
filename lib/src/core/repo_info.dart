import 'dart:io';

import 'package:path/path.dart' as path;

class DirStat {
  DirStat({required this.name});

  DirStat.fromDirectory(Directory dir) : name = getNameFromDir(dir);

  final String name;

  static String getNameFromDir(Directory dir) => path.basename(dir.path);

  static Future<List<String>> runGitCmd(
    List<String> command, {
    required String workingDirectory,
  }) async {
    final cmd = await Process.start(
      'git',
      command,
      workingDirectory: workingDirectory,
    );

    final exitCode = await cmd.exitCode;

    if (exitCode != 0) {
      final error = await cmd.stderr
          .transform(
            const SystemEncoding().decoder,
          )
          .join();
      return Future.error(error);
    }

    final result = await cmd.stdout
        .transform(
          const SystemEncoding().decoder,
        )
        .join();
    return result.trim().split('\r?\n');
  }

  static Future<bool> checkIfGitDir(String workingDirectory) async {
    return runGitCmd(
      ['rev-parse', '--show-toplevel'],
      workingDirectory: workingDirectory,
    ).then(
      (topLevel) => path.equals(
        topLevel.single.trim(),
        workingDirectory,
      ),
      onError: (error) => error.toString().contains('not a git repository')
          ? false
          : Future.error(error),
    );
  }
}

class NonGitRepo extends DirStat {
  NonGitRepo({required super.name});
}
