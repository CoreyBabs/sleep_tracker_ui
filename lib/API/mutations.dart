String saveSleepDocument = r"""
mutation AddSleep($input: SleepInput!) {
  addSleep(sleepInput: $input) {
    id
    night {
      day
      month
      year
    }
  }
}
""";

String deleteSleepDocument = r"""
mutation DeleteSleep($input: Int!) {
  deleteSleep(sleepId: $input) 
}
""";