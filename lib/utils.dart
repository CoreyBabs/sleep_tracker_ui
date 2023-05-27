import 'package:flutter/material.dart';

Color intToColor(int rgb) {
  (int, int, int) components = intToComponents(rgb);
  return Color.fromARGB(128, components.$1, components.$2, components.$3);
}

(int, int, int) intToComponents(int rgb) {

  int r = (rgb >> 16) & 0xff;
  int g = (rgb >> 8) & 0xff;
  int b = rgb & 0xff;

  return (r,g,b);
}

int colorToInt(Color color) {
  return (color.red << 16) + (color.green << 8) + color.blue; 
}