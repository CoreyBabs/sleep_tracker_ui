import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:sleep_tracker_ui/Classes/sleep.dart';
import 'package:sleep_tracker_ui/Classes/sleep_comment.dart';
import 'package:sleep_tracker_ui/Classes/tag.dart';
import 'package:sleep_tracker_ui/Widgets/multi_select_chip.dart';
import 'package:sleep_tracker_ui/API/api.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(MyApp(api: GraphQlApi()));
}

enum DialogMode { add, edit, manage }

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.api});

  final GraphQlApi api;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Sleep Journal',
        theme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: MyHomePage(title: 'Sleep Journal', api: api),

    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.api});

  final String title;
  final GraphQlApi api;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CalendarFormat calendarFormat = CalendarFormat.month;
  DateTime? selectedDay; 
  DateTime focusedDay = DateTime.now();
  List<Tag> allTags = [];
  List<String> selectedNames = [];
  List<SleepComment> comments = [];
  Sleep? sleep;
  List<Sleep> sleepsInMonth = [];

  int currentQuality = -1;
  double currentAmount = -1.0;
  String currentComment = "";
  List<Tag> currentTags = [];
  bool sleepsQueried = false;

  void _setSleeps(List<Sleep> sleeps) {
    sleepsQueried = true;
    sleepsInMonth = sleeps;
    _setSleep();
  }

  void _setSleep() {
    setState(() {
      if (sleepsInMonth.isNotEmpty && sleepsInMonth.any((element) => isSameDay(element.night, focusedDay))) {
        sleep = sleepsInMonth.firstWhere((element) => isSameDay(element.night, focusedDay));
        currentTags = sleep?.tags ?? [];
        comments = sleep?.comments ?? [];
        currentAmount = sleep?.amount ?? -1.0;
        currentQuality = sleep?.quality ?? -1;
        currentComment = comments.isNotEmpty ? comments.first.comment : "";
      }
      else {
        sleep = null;
        currentTags = [];
        comments = [];
        currentAmount = -1;
        currentQuality = -1;
        currentComment = "";
      }
    });
  }

  void _setCurrentQuality(int newQuality) {
    setState(() {
      currentQuality = newQuality;
    });
  }

  void _editSleep() {
    bool dirty = false;
    int? newQuality;
    double? newAmount;
    if (currentAmount != sleep!.amount) {
      newAmount = currentAmount;
    }

    if (currentQuality != sleep!.quality) {
      newQuality = currentQuality;
    }

    if (newQuality != null || newAmount != null) {
      widget.api.updateSleep(sleep!.id, newQuality, newAmount);
      dirty = true;
    }

    List<int> currentTagIds = currentTags.map((e) => e.id).toList();
    List<int> sleepTagIds = sleep!.tags?.map((e) => e.id).toList() ?? [];
    if (!listEquals(currentTags.map((e) => e.id).toList(), sleep!.tags?.map((e) => e.id).toList())) {
      List<int> tagsToDelete = sleepTagIds.where((e) => !currentTagIds.contains(e)).toList();
      List<int> tagsToAdd = currentTagIds.where((e) => !sleepTagIds.contains(e)).toList();

      if (tagsToDelete.isNotEmpty) {
        widget.api.deleteTagsFromSleep(sleep!.id, tagsToDelete);
        dirty = true;
      }
      if (tagsToAdd.isNotEmpty) {
        widget.api.addTagsToSleep(sleep!.id, tagsToAdd);
        dirty = true;
      }
    }

    if (currentComment.isEmpty && comments.isNotEmpty) {
      widget.api.deleteComment(comments[0].id);
      dirty = true;
    }
    else if (currentComment.isNotEmpty && comments.isEmpty) {
      widget.api.addComment(sleep!.id, currentComment);
      dirty = true;
    }
    else if (currentComment.isNotEmpty && comments.isNotEmpty && currentComment != comments[0].comment) {
      widget.api.updateComment(comments[0].id, currentComment);
      dirty = true;
    }

    if (dirty) {
      widget.api.sleepsInMonthQuery(focusedDay)
            .then((value) => _setSleeps(value));
    }
  }

  void _saveSleep(DialogMode mode) {
    if (currentAmount <= 0 || currentQuality < 1) {
      return;
    }


    if (selectedNames.isNotEmpty) {
      currentTags = Tag.getTagsByName(allTags, selectedNames);
    }
    else {
      currentTags = [];
    }

    if (mode == DialogMode.edit) {
      _editSleep();
    }
    else {
      currentTags = Tag.getTagsByName(allTags, selectedNames);
      Sleep sleepToSave = Sleep(-1, currentAmount, currentQuality, focusedDay);
      if (currentTags.isNotEmpty) {
        sleepToSave.tags = currentTags;
      }

      if (currentComment.isNotEmpty) {
        sleepToSave.comments = [SleepComment(-1, -1, currentComment)];
      }

      widget.api.saveSleep(sleepToSave)
        .then((value) {
          widget.api.sleepsInMonthQuery(focusedDay)
          .then((value) => _setSleeps(value));
        },);
    }
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
    setState(() {
      widget.api.deleteSleep(sleep!.id)
        .then((value) {
          widget.api.sleepsInMonthQuery(focusedDay)
          .then((value) => _setSleeps(value));
        },);
    });
  }

  showSleepDialog(BuildContext context, DialogMode mode) {
    var date = focusedDay.toIso8601String().split('T').first;
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
            onPressed: () { _saveSleep(mode); Navigator.pop(context); },
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
          void updateTagColor(int id, Color color) {
            setState(() {
              int idx = updatedTags.indexWhere((element) => element.id == id);
              updatedTags[idx].color = color;
            });
          }

          void addedTagColor(Color color) {
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
                                                updateTagColor(t.id, pickerColor);
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
                                                  addedTagColor(pickerColor);
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

    if (!sleepsQueried) {
      widget.api.sleepsInMonthQuery(DateTime.now()).then((value) => _setSleeps(value));
    }
    
    widget.api.allTagsQuery().then((value) => allTags = value);

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
                  _setSleep();
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
              widget.api.sleepsInMonthQuery(focusedDay).then((value) => _setSleeps(value));
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
            onPressed: () { DateTime.now().isBefore(focusedDay) 
              ? null 
              : sleep != null 
                ? showSleepDialog(context, DialogMode.edit) 
                : showSleepDialog(context, DialogMode.add);},
            tooltip: sleep != null ? 'Edit Sleep' : 'Add Sleep',
            backgroundColor: DateTime.now().isBefore(focusedDay) ? Colors.grey : Theme.of(context).colorScheme.secondary,
            child: Icon(sleep != null ? Icons.edit : Icons.add),          
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
