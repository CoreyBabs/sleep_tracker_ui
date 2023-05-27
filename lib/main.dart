import 'package:flutter/material.dart';
import 'package:sleep_tracker_ui/Classes/sleep.dart';
import 'package:sleep_tracker_ui/Classes/sleep_comment.dart';
import 'package:sleep_tracker_ui/Classes/tag.dart';
import 'package:sleep_tracker_ui/mock_data.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const MyApp());
}

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
  bool hasSleep = false;
  List<Tag> tags = constructMockTags();
  List<SleepComment> comments = constructMockComments();
  Sleep sleep = constructMockSleep()[0];

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values.
    });
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
                  hasSleep = !hasSleep;
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
                      for (var tag in tags)
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
                      leading: const Icon(Icons.grade),
                      title: Align(
                        alignment: Alignment.centerLeft,
                        child: sleep.qualityIntToQualityIcon()),
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        sleep.amount.toString(),
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
            onPressed: _incrementCounter,
            tooltip: 'Manage Tags',
            child: const Icon(Icons.label),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: hasSleep ? 'Edit Sleep' : 'Add Sleep',
            child: Icon(hasSleep ? Icons.edit : Icons.add),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
