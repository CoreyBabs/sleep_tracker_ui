import 'package:graphql/client.dart';
import 'package:sleep_tracker_ui/Classes/sleep_comment.dart';

import 'package:sleep_tracker_ui/utils.dart';
import 'package:sleep_tracker_ui/API/queries.dart';
import 'package:sleep_tracker_ui/Classes/tag.dart';
import 'package:sleep_tracker_ui/Classes/sleep.dart';

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

  Future<List<Tag>> allTagsQuery() async {
    final QueryOptions options = QueryOptions(
      document: gql(allTagsDocument),
    );

    final QueryResult result = await client.query(options);
    if (result.hasException) {
      return []; // Should handle erros better here
    }

    final List<dynamic> dtags = result.data?['allTags'] as List<dynamic>;

    return dtags.map((e) => Tag(e['id'], e['name'], intToColor(e['color']))).toList();
  }

  Future<List<Sleep>> sleepsInMonthQuery(DateTime month) async {
    final QueryOptions options = QueryOptions(
      document: gql(sleepsInMonth),
      variables: <String, dynamic> {
        'input': {
          'month': month.month,
          'year' : month.year
        }
      }
    );

    final QueryResult result = await client.query(options);
    if (result.hasException) {
      return []; // Should handle erros better here
    }

    final List<dynamic> dsleeps = result.data?['sleepsByMonth'] as List<dynamic>;

    List<Sleep> sleeps = dsleeps.map((e) =>
      Sleep(e['id'], e['amount'], e['quality'], DateTime(e['night']['year'], e['night']['month'], e['night']['day']))
    ).toList();


    for (int i = 0; i < dsleeps.length; i++) {
      var sleep = dsleeps[i];
      if (sleep['tags'].length > 0) {
        sleeps[i].tags = [];
        for (int j = 0; j < sleep['tags'].length; j++) {
          sleeps[i].tags?.add(Tag(sleep['tags'][j]['id'], sleep['tags'][j]['name'], intToColor(sleep['tags'][j]['color'])));
        }
      }

      if (sleep['comments'].length > 0) {
        sleeps[i].comments = [];
        for (int j = 0; j < sleep['comments'].length; j++) {
          sleeps[i].comments?.add(
            SleepComment(sleep['comments'][j]['id'], sleep['comments'][j]['sleepId'], sleep['comments'][j]['comment']));
        }
      }
    }

    return sleeps;    
  }
}