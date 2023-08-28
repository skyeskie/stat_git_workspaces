import 'package:repository_url/repository_url.dart';

class GitRemote {
  final String name;
  final String branch;
  final RepositoryUrl uri;
  final int ahead;
  final int behind;

  GitRemote({
    required this.name,
    required this.branch,
    required this.uri,
    this.ahead = 0,
    this.behind = 0,
  });

  bool get isSync => ahead == 0 && behind == 0;
}
