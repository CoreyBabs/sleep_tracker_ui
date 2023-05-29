import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:math';

import 'package:sleep_tracker_ui/Classes/sleep.dart';
import 'package:sleep_tracker_ui/Classes/sleep_comment.dart';
import 'package:sleep_tracker_ui/Classes/tag.dart';
import 'package:sleep_tracker_ui/mock_data.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sleep_tracker_ui/Widgets/multi_select_chip.dart';

void main() {
  runApp(const MyApp());
}

enum DialogMode { add, edit, manage }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Journal',
      theme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(title: 'Sleep Journal'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// https://github.com/aleksanderwozniak/table_calendar/blob/master/example/lib/pages/basics_example.dart
class _MyHomePageState extends State<MyHomePage> {
  CalendarFormat calendarFormat = CalendarFormat.month;
  DateTime? selectedDay; 
  DateTime focusedDay = DateTime.now();
  List<Tag> allTags = constructMockTags();
  List<String> selectedNames = [];
  List<SleepComment> comments = [];//constructMockComments();
  Sleep? sleep;

  int currentQuality = -1;
  double currentAmount = -1.0;
  String currentComment = "";
  List<Tag> currentTags = [];

  void _setCurrentQuality(int newQuality) {
    setState(() {
      currentQuality = newQuality;
    });
  }

  void _saveSleep() {
    // TODO: call db save here to construct sleep

    if (currentAmount <= 0 || currentQuality < 1) {
      return;
    }

    setState(() {
      currentTags = Tag.getTagsByName(allTags, selectedNames);
      sleep = Sleep(-1, currentAmount, currentQuality, DateTime.now());
      sleep?.tags = currentTags;
      if (currentComment.isNotEmpty) {
        sleep?.comments = [SleepComment(-1, sleep?.id ?? -1, currentComment)];
        comments = sleep?.comments ?? [];
      }
    });
  }

  void _updateTags(List<Tag> updatedTags) {

    List<int> allTagIds = allTags.map((e) => e.id).toList();
    List<int> updatedTagIds = updatedTags.map((e) => e.id).toList();

    List<Tag> tagsToAdd = updatedTags.where((element) => !allTagIds.contains(element.id)).toList();
    List<Tag> tagsToDelete = [];//allTags.where((element) => !updatedTagIds.contains(element.id)).toList();

    List<Tag> tagsToUpdate = [];
    for (Tag tag in allTags) {
      if (updatedTagIds.contains(tag.id)) {
        Tag newTag = updatedTags.firstWhere((element) => tag.id == element.id);
        if (newTag.name != tag.name || newTag.color != newTag.color) {
          tagsToUpdate.add(newTag);
        }
      }
      else {
        tagsToDelete.add(tag);
      }
    }

    // TODO: update all tags here and save in db
  }

  void _deleteSleep() {
    // TODO: delete sleep from db here
    setState(() {
      sleep = null;
      currentTags = [];
      comments = [];
    });
  }

  void _deleteTag(Tag tag) {
    // TODO: delete tag from db here
    setState(() {
      allTags.removeWhere((element) => tag.id == element.id);
    });
  }

  showSleepDialog(BuildContext context, DialogMode mode) {
    var date = DateTime.now().toIso8601String().split('T').first;
    showDialog(context: context, 
      builder: (context) {
        int selectedQuality = -1;
        TextEditingController amountFieldController = TextEditingController();
        TextEditingController commentFieldController = TextEditingController();
        String prefix = "Add";

        var buttons = [
          TextButton(
            onPressed: () { Navigator.pop(context); },
            child: const Text("Cancel")),
          TextButton(
            onPressed: () { _saveSleep(); Navigator.pop(context); },
            child: const Text("Save")),];

        if (mode == DialogMode.edit) {
          amountFieldController.text = currentAmount.toString();
          commentFieldController.text = currentComment.toString();
          prefix = "Edit";
          selectedQuality = currentQuality;

          buttons.insert(1,
            TextButton(
              onPressed: () { _deleteSleep(); Navigator.pop(context); },
              child: const Text("Delete"))
          );
        }

        return StatefulBuilder(
          builder: (context, setState) { 
            return AlertDialog(
              title: Text('$prefix Sleep for $date'),
              content: Column(
              children: [
                Row(
                  children: [
                    const Text(" Quality: "),
                    for (int i = 1; i <= 5; i++)
                      IconButton(
                        onPressed: () { _setCurrentQuality(i); setState(() => selectedQuality = i); }, 
                        icon: Icon(Sleep.externalIntToQualityIcon(i).icon, color: selectedQuality == i ? Theme.of(context).colorScheme.secondary : null)),
                    ],
                  ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 7)),
                Row(
                  children: [
                    const Text("Amount: "),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                    Flexible(
                      child:
                        TextField(
                          controller: amountFieldController,
                          showCursor: true,
                          autocorrect: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[0-9.]'))
                          ],
                          onChanged: (value) {
                            double? newValue = double.tryParse(value);
                            if (newValue == null) {
                              currentAmount = -1;
                              setState(() => amountFieldController.text = "0");
                            }
                            else {
                              currentAmount = newValue;
                            }
                          },
                      )
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 7)),
                Row(children: [
                    const Text("Tags: "),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
                      child: SingleChildScrollView(
                        child: MultiSelectChip(
                          [for (var t in allTags) t.name],
                          (selectedList) {
                            setState(() {
                            selectedNames = selectedList;
                            });
                          },
                          [for (var t in currentTags) t.name]
                        ),
                    )
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 7)),
                Row(
                  children: [
                    const Text("Notes: "),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                    Container(
                      constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
                      child: TextField(
                        controller: commentFieldController,
                        minLines: 1,
                        maxLines: null,
                        showCursor: true,
                        autocorrect: false,
                        onChanged: (value) {
                            currentComment = value;
                        },
                        ),
                    )
                  ],
                ),
                ],
              ),
              actions: buttons,
            ); 
          });
      },
    );
  }

  showManageTagsDialog(BuildContext context) {
    showDialog(context: context, 
      builder: (context) {
        List<Tag> updatedTags = allTags;
        Color addedColor = Colors.white;
        String addedName = "";
        int newId = allTags.map((e) => e.id).reduce(max) + 1;

        return StatefulBuilder(
          builder: (context, setState) { 
          void _updateTagColor(int id, Color color) {
            setState(() {
              int idx = updatedTags.indexWhere((element) => element.id == id);
              updatedTags[idx].color = color;
            });
          }

          void _addedTagColor(Color color) {
            setState(() {
              addedColor = color;
            });
          }

            return AlertDialog(
              title: const Text('Manage Tags'),
              content: Column(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 200,
                    width: 200,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (var t in updatedTags)
                          Row(
                            children: [
                              Flexible(child:
                                TextField(
                                  controller: TextEditingController(text: t.name),
                                  autocorrect: false,
                                  minLines: 1,
                                  maxLines: null,
                                  showCursor: true,
                                  onChanged: (value) {
                                    setState(() {
                                      int idx = updatedTags.indexWhere((element) => element.id == t.id);
                                      updatedTags[idx].name = value;
                                    },);
                                  },),),
                              IconButton(icon: Icon(Icons.color_lens, color: t.color,),
                               onPressed: () {
                                showDialog(context: context, 
                                  builder: (context) {
                                    Color pickerColor = t.color;
                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return AlertDialog(
                                          title: const Text("Pick a color"),
                                          content: SingleChildScrollView(
                                            child: ColorPicker(
                                              pickerColor: pickerColor,
                                              onColorChanged: (value) {
                                                setState(() => pickerColor = value);
                                              },
                                            ),
                                          ),
                                          actions: [
                                            ElevatedButton(child: const Text("Done"),
                                            onPressed: () {
                                              setState(() {
                                                _updateTagColor(t.id, pickerColor);
                                              },);
                                              Navigator.of(context).pop();
                                            },)
                                          ],
                                        );
                                    },
                                   );
                                });
                               },),
                              IconButton(icon: const Icon(Icons.delete_forever),
                               onPressed: () {
                                setState(() {
                                  updatedTags.removeWhere((element) => t.id == element.id);
                                });
                               },),
                            ],
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 7)),
                          Row(
                            children: [
                              Flexible(child:
                                TextField(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: "Add Tag"
                                  ),
                                  autocorrect: false,
                                  minLines: 1,
                                  maxLines: null,
                                  showCursor: true,
                                  onChanged: (value) {
                                    addedName = value;
                                  },
                                  ),
                                ),
                                IconButton(icon: Icon(Icons.color_lens, color: addedColor,),
                                onPressed: () {
                                  showDialog(context: context, 
                                    builder: (context) {
                                      Color pickerColor = addedColor;
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return AlertDialog(
                                            title: const Text("Pick a color"),
                                            content: SingleChildScrollView(
                                              child: ColorPicker(
                                                pickerColor: pickerColor,
                                                onColorChanged: (value) {
                                                  setState(() => pickerColor = value);
                                                },
                                              ),
                                            ),
                                            actions: [
                                              ElevatedButton(child: const Text("Done"),
                                              onPressed: () {
                                                setState(() {
                                                  _addedTagColor(pickerColor);
                                                },);
                                                Navigator.of(context).pop();
                                              },)
                                            ],
                                          );
                                      },
                                    );
                                  });
                              }),
                              IconButton(icon: const Icon(Icons.save),
                                onPressed: () {
                                  if (addedName.isEmpty) {
                                    return;
                                  }
                                  setState(() {
                                    updatedTags.add(Tag(newId, addedName, addedColor));
                                    addedColor = Colors.white;
                                    addedName = "";
                                    newId++;
                                  });
                               }),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                 ],
              ),
              actions: [
                TextButton(
                  onPressed: () { Navigator.pop(context); },
                  child: const Text("Cancel")),
                TextButton(
                  onPressed: () { _updateTags(updatedTags); Navigator.pop(context); },
                  child: const Text("Save")),
              ],
            ); 
          });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime firstDay = DateTime(DateTime.now().year, 1, 1);
    DateTime lastDay = DateTime(DateTime.now().year, DateTime.now().month + 7, 0);

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title,
        style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary)),
      ),
      body: 
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TableCalendar (
              firstDay: firstDay,
              lastDay: lastDay,
              currentDay: DateTime.now(),
              focusedDay: focusedDay,
              calendarFormat: calendarFormat,
              rowHeight: 60,
              weekendDays: const [],
              selectedDayPredicate: (day) {
              // Use `selectedDayPredicate` to determine which day is currently selected.
              // If this returns true, then `day` will be marked as selected.

              // Using `isSameDay` is recommended to disregard
              // the time-part of compared DateTime objects.
              return isSameDay(selectedDay, day);
            },
            onDaySelected: (newSelectedDay, newFocusedDay) {
              if (!isSameDay(selectedDay, newSelectedDay)) {
                // Call `setState()` when updating the selected day
                setState(() {
                  selectedDay = newSelectedDay;
                  focusedDay = newFocusedDay;
                  sleep = null; // TODO: look for new sleep
                  comments = []; // TODO: update comments properly
                  currentTags = []; // TODO: update tag properly
                });
              }
            },
            onFormatChanged: (format) {
              if (calendarFormat != format) {
                // Call `setState()` when updating calendar format
                setState(() {
                  calendarFormat = format;
                });
              }
            },
            onPageChanged: (newFocusedDay) {
              // No need to call `setState()` here
              focusedDay = newFocusedDay;
            },), 
            const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tags:',
                style: Theme.of(context).textTheme.headlineSmall
                    )),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
            Align(
              alignment: Alignment.centerLeft,
              child:
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 30
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 9)),
                      for (var tag in currentTags)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: tag.color,
                            borderRadius:  BorderRadius.circular(5.0)
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          child: Text(tag.name),),
                      ],
                  ),
                ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 9)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Info:',
                style: Theme.of(context).textTheme.headlineSmall
                    )),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 9)),         
            Flexible(
              child:
                ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: sleep != null ? const Icon(Icons.grade) : null,
                      title: Align(
                        alignment: Alignment.centerLeft,
                        child: sleep?.qualityIntToQualityIcon()),
                    ),
                    ListTile(
                      leading: sleep != null ? const Icon(Icons.access_time) : null,
                      title: Text(
                        sleep?.amount.toString() ?? "",
                      )
                    ),
                    for (var comment in comments)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.comment),
                            title: Text(
                              comment.comment,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                  ],)
                ),
              ],
            ),
      floatingActionButton: 
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {showManageTagsDialog(context);},
            tooltip: 'Manage Tags',
            child: const Icon(Icons.label),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
          FloatingActionButton(
            onPressed: () { DateTime.now().isBefore(selectedDay ?? DateTime.now()) 
              ? null 
              : sleep != null 
                ? showSleepDialog(context, DialogMode.edit) 
                : showSleepDialog(context, DialogMode.add);},
            tooltip: sleep != null ? 'Edit Sleep' : 'Add Sleep',
            backgroundColor: DateTime.now().isBefore(selectedDay ?? DateTime.now()) ? Colors.grey : Theme.of(context).colorScheme.secondary,
            child: Icon(sleep != null ? Icons.edit : Icons.add),          
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
