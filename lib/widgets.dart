import 'package:flutter/material.dart';
import 'package:github/github.dart';

import 'Util/functions.dart';


class InfoPage extends StatefulWidget {
  final GitHub gitHub;
  const InfoPage({Key? key, required this.gitHub}) : super(key: key);

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {

  int selected  = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          destinations:  const [
            NavigationRailDestination(
              icon: Icon(Icons.menu),
              label: Text('repos')),

            NavigationRailDestination(icon: Icon(Icons.info), label: Text('issues')),

            NavigationRailDestination(icon: Icon(Icons.code), label: Text('pr\'s')),
          ],
          selectedIndex: selected,
          onDestinationSelected: (index) => setState(() {
          selected = index;
        }),
        ),

        const VerticalDivider(
          width: 2,
          indent: 42,
          endIndent: 42,
        ),

        Expanded(
          child: IndexedStack(
            index: selected,
            children: [
              RepositoriesList(github: widget.gitHub),
              AssignedIssuesList(github: widget.gitHub),
              PullRequestsList(github: widget.gitHub),
            ],
          ),
        )
      ],
    );
  }
}



class RepositoriesList extends StatefulWidget {
  final GitHub github;
  const RepositoriesList({Key? key, required this.github}) : super(key: key);

  @override
  State<RepositoriesList> createState() => _RepositoriesListState();
}

class _RepositoriesListState extends State<RepositoriesList> {

  @override
  void initState() {
    _repositories = widget.github.repositories.listRepositories().toList();
    super.initState();
  }
  final ScrollController _controller = ScrollController();
  late Future<List<Repository>> _repositories;


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Repository>>(
      future: _repositories,
      builder: (context, snapshot) {
        if(snapshot.hasError){
          return Center(child: Text('${snapshot.error}'));
        } else if (!snapshot.hasData){
          return const Center(child: CircularProgressIndicator());
        } 
        
        var repos = snapshot.data;
        return ListView.builder(
          controller: _controller,
          itemCount: repos!.length,
          itemBuilder: (context, index) {
            var r = repos![index];
            return ListTile(
              title: Text('${r.owner!.login ?? ''} / ${r.name}'),
              subtitle: Text(r.description),
              onTap: () => launchUrl(context, r.htmlUrl)
              );
              },
            );
          }
          );
      }
  }



class AssignedIssuesList extends StatefulWidget {
  final GitHub github;
  const AssignedIssuesList({Key? key, required this.github}) : super(key: key);

  @override
  State<AssignedIssuesList> createState() => _AssignedIssuesListState();
}

class _AssignedIssuesListState extends State<AssignedIssuesList> {

  @override
  void initState() {
    super.initState();
    _issue = widget.github.issues.listByUser().toList();
  }
  final ScrollController _controller = ScrollController();
  late Future<List<Issue>> _issue;

  String _nameWithOwner(Issue assignedIssue) {
    final endIndex = assignedIssue.url.lastIndexOf('/issues/');
    return assignedIssue.url.substring(29, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Issue>>(
      future: _issue,
      builder: ((context, snapshot) {
         if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if(snapshot.data!.isEmpty) {
          return const Center(child: Text('There is noting to display'));
        }
        var iss = snapshot.data;
        return ListView.builder(
          controller: _controller,
          itemCount: iss!.length,
          itemBuilder: (context, index) {
            var i = iss[index];
            return ListTile(
              title: Text(i.title),
              subtitle: Text('${_nameWithOwner(i)} - Issue #${i.number}\n opened by ${i.user?.login ?? ''}'),
              onTap: () => launchUrl(context, i.htmlUrl),
            );
          }    
        );
      }),
    ); 
  }
}




class PullRequestsList extends StatefulWidget {
  final GitHub github;
  const PullRequestsList({Key? key, required this.github}) : super(key: key);

  @override
  State<PullRequestsList> createState() => _PullRequestsListState();
}

class _PullRequestsListState extends State<PullRequestsList> {

  @override
  void initState() {
    pullRequest = widget.github.pullRequests.list(RepositorySlug('flutter', 'flutter')).toList();
    super.initState();
  }

  late Future<List<PullRequest>> pullRequest;
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PullRequest>>(
      future: pullRequest,
      builder: (context, snapshot) {
         if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var pr = snapshot.data;
        return ListView.builder(
          controller: _controller,
          itemCount: pr!.length,
          itemBuilder: (context, index) {
            var p = pr[index];
            return ListTile(
              title: Text(p.title ?? ''),
              subtitle: Text('flutter/flutter PR #${p.number}\n opened by ${p.user?.login ?? ''}'),
              onTap: () => launchUrl(context, p.htmlUrl ?? ''),
            );
            }
        );
      },
    );
  }
}