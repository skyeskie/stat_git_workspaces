import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/stat_git_workspaces.dart';

Future<int> main(List<String> arguments) async {
  AnsiX.allowPrint = true;
  AnsiX.ensureSupportsAnsi();
  return statOnWorkdir(arguments);
}
