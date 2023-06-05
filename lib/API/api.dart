import 'package:graphql/client.dart';

import 'package:sleep_tracker_ui/utils.dart';
import 'package:sleep_tracker_ui/API/queries.dart';
import 'package:sleep_tracker_ui/Classes/tag.dart';

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
}