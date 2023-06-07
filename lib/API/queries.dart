String allTagsDocument = r"""
query AllTags {
  allTags {
    id
    color
    name
  }
}
""";

String sleepsInMonth = r"""
query SleepsInMonth($input: SleepsByMonthInput!) {
  sleepsByMonth(month: $input) {
    id
    night {
      day
      month
      year
      date
    }
    amount
    quality
    tags {
      id
      name
      color
    }
    comments {
      id
      sleepId
      comment
    }
  }
}
""";