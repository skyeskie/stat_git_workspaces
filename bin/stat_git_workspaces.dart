import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/stat_git_workspaces.dart';

void main(List<String> arguments) {
  AnsiX.allowPrint = true;
  AnsiX.ensureSupportsAnsi();
  statOnWorkdir();
}
