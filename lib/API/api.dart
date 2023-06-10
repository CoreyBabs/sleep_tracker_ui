import 'package:graphql/client.dart';
import 'package:sleep_tracker_ui/API/mutations.dart';
import 'package:sleep_tracker_ui/Classes/sleep_comment.dart';

import 'package:sleep_tracker_ui/utils.dart';
import 'package:sleep_tracker_ui/API/queries.dart';
import 'package:sleep_tracker_ui/Classes/tag.dart';
import 'package:sleep_tracker_ui/Classes/sleep.dart';

// TODO: add tag, delete tag, update tag 

class GraphQlApi {
  late GraphQLClient client;

  GraphQlApi() {
    final httpLink = HttpLink(
      'http://localhost:8000',
    );

    client = GraphQLClient(
      /// **NOTE** The default store is the InMemoryStore, which does NOT persist to disk
      cache: GraphQLCache(),
      link: httpLink);
  }

  Sleep _dbSleepToSleep(dynamic dbSleep) {
    Sleep sleep = Sleep(
      dbSleep['id'],
      dbSleep['amount'],
      dbSleep['quality'],
      DateTime(dbSleep['night']['year'], dbSleep['night']['month'], dbSleep['night']['day']));

      if (dbSleep['tags'].length > 0) {
        sleep.tags = [];
        for (int j = 0; j < dbSleep['tags'].length; j++) {
          sleep.tags?.add(_dbTagToTag(dbSleep['tags'][j]));
        }
      }

      if (dbSleep['comments'].length > 0) {
        sleep.comments = [];
        for (int j = 0; j < dbSleep['comments'].length; j++) {
          sleep.comments?.add(_dbCommentToComment(dbSleep['comments'][j]));
        }
      }

      return sleep;
  }

  Tag _dbTagToTag(dynamic dbTag) {
    return Tag(dbTag['id'], dbTag['name'], intToColor(dbTag['color']));
  }

  SleepComment _dbCommentToComment(dynamic dbComment) {
    return SleepComment(dbComment['id'], dbComment['sleepId'], dbComment['comment']);
  }

  Future<List<Tag>> allTagsQuery() async {
    final QueryOptions options = QueryOptions(
      document: gql(allTagsDocument),
      fetchPolicy: FetchPolicy.networkOnly
    );

    final QueryResult result = await client.query(options);
    if (result.hasException) {
      return []; // Should handle erros better here
    }

    final List<dynamic> dtags = result.data?['allTags'] as List<dynamic>;

    return dtags.map((e) => _dbTagToTag(e)).toList();
  }

  Future<List<Sleep>> sleepsInMonthQuery(DateTime month) async {
    final QueryOptions options = QueryOptions(
      document: gql(sleepsInMonth),
      variables: <String, dynamic> {
        'input': {
          'month': month.month,
          'year' : month.year
        }
      },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await client.query(options);
    if (result.hasException) {
      return []; // Should handle erros better here
    }

    final List<dynamic> dsleeps = result.data?['sleepsByMonth'] as List<dynamic>;

    List<Sleep> sleeps = dsleeps.map((e) => _dbSleepToSleep(e)).toList();
    return sleeps;    
  }

  Future<int> saveSleep(Sleep sleep) async {
    Map<String, dynamic> variable = {};
    variable['night'] = sleep.night.toIso8601String().split('T').first;
    variable['amount'] = sleep.amount;
    variable['quality'] = sleep.quality;

    if (sleep.tags != null && (sleep.tags?.isNotEmpty ?? false)) {
      variable['tags'] = sleep.tags?.map((e) => e.id).toList();
    }

    if (sleep.comments != null && (sleep.comments?.isNotEmpty ?? false)) {
      variable['comments'] = sleep.comments?.map((e) => e.comment).toList();
    }

    final MutationOptions options = MutationOptions(
      document: gql(saveSleepDocument),
      variables: <String, dynamic> {
        "input" : variable
      },
      fetchPolicy: FetchPolicy.networkOnly
    );

    final QueryResult result = await client.mutate(options);
    if (result.hasException) {
      print(result.exception);
      return -1; // Should handle erros better here
    }

    return result.data?['addSleep']['id'];
  }

  Future deleteSleep(int id) async {
    final MutationOptions options = MutationOptions(
      document: gql(deleteSleepDocument),
      variables: <String, dynamic> {
        'input': id
      },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await client.mutate(options);
    if (result.hasException) {
      return; // Should handle erros better here
    }
  }

  Future<Sleep?> updateSleep(int sleepId, int? quality, double? amount) async {
    if (quality == null && amount == null) {
      return null;
    }

    Map<String, dynamic> variable = {};
    variable['sleepId'] = sleepId;
    if (quality != null) {
      variable['quality'] = quality;
    }
    if (amount != null) {
      variable['amount'] = amount;
    }

    final MutationOptions options = MutationOptions(
      document: gql(updateSleepDocument),
      variables: <String, dynamic> { 'input' : variable },
      fetchPolicy: FetchPolicy.networkOnly);

    final QueryResult result = await client.mutate(options);

     if (result.hasException) {
      print(result.exception);
      return null; // Should handle erros better here
    }

    return _dbSleepToSleep(result.data?['updateSleep']);
  }

  Future addTagsToSleep(int sleepId, List<int> tagIds) async {
    Map<String, dynamic> variable = {};
    variable['sleepId'] = sleepId;
    variable['tagIds'] = tagIds;

    final MutationOptions options = MutationOptions(
      document: gql(addTagToSleepDocument),
      variables: <String, dynamic> { 'input' : variable },
      fetchPolicy: FetchPolicy.networkOnly);

    final QueryResult result = await client.mutate(options);

     if (result.hasException) {
      print(result.exception);
      return; // Should handle erros better here
    }
  }

  Future deleteTagsFromSleep(int sleepId, List<int> tagIds) async {
    for (var id in tagIds) {
      Map<String, dynamic> variable = {};
      variable['sleepId'] = sleepId;
      variable['tagId'] = id;

      final MutationOptions options = MutationOptions(
        document: gql(removeTagFromSleepDocument),
        variables: <String, dynamic> { 'input': variable},
        fetchPolicy: FetchPolicy.networkOnly);

      final QueryResult result = await client.mutate(options);

      if (result.hasException) {
        print(result.exception);
        continue; // Should handle erros better here
      }
    }
  }

  Future addComment(int sleepId, String comment) async {
    Map<String, dynamic> variable = {};
    variable['sleepId'] = sleepId;
    variable['comment'] = comment;

    final MutationOptions options = MutationOptions(
      document: gql(addCommentToSleepDocument),
      variables: <String, dynamic> { 'input' : variable },
      fetchPolicy: FetchPolicy.networkOnly);

    final QueryResult result = await client.mutate(options);

     if (result.hasException) {
      print(result.exception);
      return; // Should handle erros better here
    }
  }

  Future deleteComment(int commentId) async {
    final MutationOptions options = MutationOptions(
      document: gql(deleteCommentDocument),
      variables: <String, dynamic> {
        'input': commentId
      },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await client.mutate(options);
    if (result.hasException) {
      return; // Should handle erros better here
    }
  }

  Future updateComment(int commentId, String comment) async {
    Map<String, dynamic> variable = {};
    variable['commentId'] = commentId;
    variable['comment'] = comment;

    final MutationOptions options = MutationOptions(
      document: gql(updateCommentDocument),
      variables: <String, dynamic> {
        'input': variable
      },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await client.mutate(options);
    if (result.hasException) {
      return; // Should handle erros better here
    }
  }
}