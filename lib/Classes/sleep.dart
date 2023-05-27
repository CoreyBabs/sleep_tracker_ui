import 'package:flutter/material.dart';
import 'package:sleep_tracker_ui/Classes/sleep_comment.dart';
import 'package:sleep_tracker_ui/Classes/tag.dart';

class Sleep {
  final int id;
  final double amount;
  final int quality;
  final DateTime night;
  List<Tag>? tags;
  List<SleepComment>? comments;

  Sleep(this.id, this.amount, this.quality, this.night);

  Icon qualityIntToQualityIcon() {

    IconData iconData = Icons.sentiment_neutral_outlined;
    switch (quality) {
      case 1: iconData = Icons.sentiment_very_dissatisfied_outlined;
      case 2: iconData = Icons.sentiment_dissatisfied_outlined;
      case 3: iconData = Icons.sentiment_neutral_outlined;
      case 4: iconData = Icons.sentiment_satisfied_outlined;
      case 5: iconData = Icons.sentiment_very_satisfied_outlined;
    }

    return Icon(iconData);
  }
}