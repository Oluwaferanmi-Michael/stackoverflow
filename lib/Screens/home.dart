import 'package:flutter/material.dart';
import 'package:stackoverflow/cred.dart';
import 'package:github/github.dart';
import 'package:stackoverflow/widgets.dart';

// import 'package:window_to_front/window_to_front.dart';

import '../Auth/auth.dart';


class HomPage extends StatelessWidget {
  const HomPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GitHubAuthWidget(
      builder: (context, httpClient) {
        return FutureBuilder<CurrentUser>(
          future: viewerDetail(httpClient.credentials.accessToken),
          builder: (context, snap) {
            return Scaffold(
              body: InfoPage(
                gitHub: _getGitHUb(httpClient.credentials.accessToken)
              )
            );
          },  
        );
      },

      gitHubClientID: gitHubClientID,
      gitHubSecret: gitHubSecret,
      gitHubScope: gitHubScope,
    );
  }
}

Future<CurrentUser> viewerDetail(String access_token){
  final github = GitHub(auth: Authentication.withToken(access_token));
  return github.users.getCurrentUser();
}

GitHub _getGitHUb(String access_token){
  return  GitHub(auth: Authentication.withToken(access_token));
}