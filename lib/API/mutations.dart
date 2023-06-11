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

String updateSleepDocument = r"""
  mutation UpdateSleep($input: UpdateSleepInput!) {
  updateSleep(sleepInput: $input) {
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

String updateTagDocument = r"""
mutation UpdateTag($input: UpdateTagInput!) {
  updateTag(tagInput: $input) {
    id
    name
    color
  }
}
""";

String updateCommentDocument = r"""
mutation UpdateComment($input: UpdateCommentInput!) {
  updateComment(commentInput: $input) {
    id
    sleepId
    comment
  }
}
""";

String addTagToSleepDocument = r"""
mutation AddTagToSleep($input: AddTagsToSleepInput!) {
  addTagsToSleep(addTagsToSleepInput: $input) {
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

String removeTagFromSleepDocument = r"""
mutation RemoveTagToSleep($input: RemoveTagFromSleepInput!) {
  removeTagFromSleep(removeTagInput: $input) {
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

String addCommentToSleepDocument = r"""
mutation AddCommentToSleep($input: AddCommentToSleepInput!) {
  addCommentToSleep(addCommentToSleepInput: $input) {
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

String deleteCommentDocument = r"""
mutation DeleteComment($input: Int!) {
  deleteComment(commentId: $input) 
}
""";

String addTagDocument = r"""
mutation AddTag($input: TagInput!) {
  addTag(tagInput: $input) {
    id
    name
    color
  }
}
""";

String deleteTagDocument = r"""
mutation DeleteTag($input: Int!) {
  deleteTag(tagId: $input) 
}
""";
