import 'package:fluent_ui/generated/intl/messages_ar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:stackoverflow/cred.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

final _authorizationEndpoint = Uri.parse('https://github.com/login/oauth/authorize');

final _tokenEndpoint = Uri.parse('https://github.com/login/oauth/access_token');

class AuthWidget extends StatefulWidget {
  final AuthenticatedBuilder? builder;
  final String? gitHubClientID;
  final String? gitHubSecret;
  final List<String>? gitHubScope;


  const AuthWidget({
    Key? key,
    this.builder, this.gitHubClientID, this.gitHubSecret, this.gitHubScope,
  }) : super(key: key);

  @override
  State<AuthWidget> createState() => _AuthWidgetState();
}

typedef AuthenticatedBuilder = Widget Function(
  BuildContext context, oauth2.Client client
);

class _AuthWidgetState extends State<AuthWidget> {

  HttpServer? _redirectServer;
  oauth2.Client? _client;

  @override
  Widget build(BuildContext context) {

    final client = _client;
    if(client != null){
      return widget.builder!(context, client);
    }

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Login to Github'),
          onPressed: () async {
            await _redirectServer?.close();
            // Bind to an ephemeral port on localhost
            _redirectServer = await HttpServer.bind('localhost', 0);
            var authenticatedHttpClient = await _getOAuth2Client(
              Uri.parse('http://localhost:${_redirectServer!.port}/auth')
            );
            setState(() {
              _client = authenticatedHttpClient;
            });
          }),
        ),
      );
  }
  
Future<oauth2.Client> _getOAuth2Client(Uri redirectUri) async {
    if (widget.gitHubClientID!.isEmpty || widget.gitHubSecret!.isEmpty) {
      throw const GithubLoginException(
          'githubClientId and githubClientSecret must be not empty. '
          'See `lib/github_oauth_credentials.dart` for more detail.');
    }
    var grant = oauth2.AuthorizationCodeGrant(
      gitHubClientID,
      _authorizationEndpoint,
      _tokenEndpoint,
      secret: gitHubSecret,
      httpClient: _JsonAcceptingHttpClient(),
    );

    var authorizationUrl = grant.getAuthorizationUrl(redirectUri, scopes: widget.gitHubScope);

    await _redirect(authorizationUrl);

    var responseQueryParameters = await _listen();  
    var client = await grant.handleAuthorizationResponse(responseQueryParameters);
    return client;
  }

  Future<void> _redirect(Uri authorizationUrl) async {
    if (await canLaunchUrl(authorizationUrl)){
      await launchUrl(authorizationUrl);
    } else {
      throw GithubLoginException('could not Launch $authorizationUrl');
    }
  }

  Future<Map<String, String>> _listen() async{
    var request = await _redirectServer!.first;
    var params = request.uri.queryParameters;
    var req = request.response;

    req.statusCode = 200;
    req.headers.set('content', 'text');
    req.writeln('Authenticated you can close');

    await req.close();
    await _redirectServer!.close();
    _redirectServer = null;

    return params;
  }
}

class _JsonAcceptingHttpClient extends http.BaseClient {
  final httpClient = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request){
    request.headers['Accept'] = 'application/json';
    return httpClient.send(request);
  }
}

class GithubLoginException implements Exception {
  const GithubLoginException(this.message);
  final String message;
  @override
  String toString() => message;
}
