import 'package:flutter/material.dart';
import 'Classes/sleep.dart';
import 'Classes/tag.dart';
import 'Classes/sleep_comment.dart';

const List<String> tagNames = ["Chocolate", "Screen", "Alcohol"];
const List<Color> tagColors = [Colors.cyan, Colors.deepPurple, Colors.orange];
const List<String> comments = ["First comment", "Long commment ajfgjdgfadgsfsljdgflsjdkgldkgfslkjdfskdjhfskdjhfskjdhfskjdhfsdkljfh", "more", "scroll", "more scroll", "last"];

List<Tag> constructMockTags() {
  return [for(int i = 0; i < 5; i++) Tag(i, tagNames[i % 3], tagColors[i % 3])];
}

List<SleepComment> constructMockComments() {
  return [for(int i = 0; i < 6; i++) SleepComment(i,i,comments[i])];
}

List<Sleep> constructMockSleep() {
  return [Sleep(1, 7.5, 4, DateTime.now())];
}