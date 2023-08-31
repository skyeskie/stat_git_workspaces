import 'package:repository_url/repository_url.dart';

RepositoryUrl makeSshRepositoryUrl({
  String userInfo = 'git',
  required String host,
  required String siteUser,
  required String repoName,
}) =>
    RepositoryUrl.altSsh(
      userInfo: userInfo,
      host: host,
      path: '$siteUser/$repoName',
    );

extension RepoUserExtensions on RepositoryUrl {
  String get user {
    // Use not empty, because `user@host:/user/repo` is valid
    return pathSegment.firstWhere((element) => element.isNotEmpty);
  }

  String get organization => user;
}
