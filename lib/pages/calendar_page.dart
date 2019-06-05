import 'package:calendar_poc/models/user.dart';
import 'package:calendar_poc/services/calendar_service.dart';

import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'package:date_utils/date_utils.dart';
import 'package:googleapis/calendar/v3.dart' as CalendarAPI;


class CalendarPage extends StatefulWidget {
  CalendarPage({Key key, this.user}) : super(key: key);

  final User user;

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with TickerProviderStateMixin {
  User _user;
  bool _isLoading;
  Map<DateTime, List> _events;
  Map<DateTime, List> _visibleEvents;


  DateTime _selectedDay;

  List _selectedEvents;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _user = widget.user;
    _isLoading = true;
    _selectedDay = DateTime.now();
    _events = {};
    _visibleEvents = _events;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.forward();

    _updateCalendar();
  }

  /*

  UI Elements

  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Calendar")),
        body: Stack(
          children: <Widget>[
            RefreshIndicator(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  _buildTableCalendarWithBuilders(),
                  Expanded(child: _buildEventList()),
                ],
              ),
              onRefresh: _refreshCalendar,
            ),
            _showCircularProgress(),
          ],
        ));
  }

  Widget _buildTableCalendarWithBuilders() {
    return TableCalendar(
      locale: 'en_US',
      events: _visibleEvents,
      initialCalendarFormat: CalendarFormat.week,
      formatAnimation: FormatAnimation.slide,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableGestures: AvailableGestures.all,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Doua Saptamani',
        CalendarFormat.week: 'Luna',
        CalendarFormat.twoWeeks: 'Saptamana',
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendStyle: TextStyle().copyWith(color: Colors.blue[800]),
        holidayStyle: TextStyle().copyWith(color: Colors.blue[800]),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekendStyle: TextStyle().copyWith(color: Colors.blue[600]),
      ),
      headerStyle: HeaderStyle(
        formatButtonTextStyle:
        TextStyle().copyWith(color: Colors.white, fontSize: 15.0),
        formatButtonDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      builders: CalendarBuilders(
        selectedDayBuilder: (context, date, _) {
          return FadeTransition(
            opacity: Tween(begin: 0.0, end: 1.0).animate(_controller),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  color: Theme.of(context).primaryColor),
              margin: const EdgeInsets.all(4.0),
              padding: const EdgeInsets.only(top: 5.0, left: 6.0),
              width: 100,
              height: 100,
              child: Text(
                '${date.day}',
                style: TextStyle().copyWith(fontSize: 16.0),
              ),
            ),
          );
        },
        todayDayBuilder: (context, date, _) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            padding: const EdgeInsets.only(top: 5.0, left: 6.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              color: Theme.of(context).primaryColor.withAlpha(90),
            ),
            width: 100,
            height: 100,
            child: Text(
              '${date.day}',
              style: TextStyle().copyWith(fontSize: 16.0),
            ),
          );
        },
        markersBuilder: (context, date, events, holidays) {
          final children = <Widget>[];

          if (events != null) {
            children.add(
              Positioned(
                right: 1,
                bottom: 1,
                child: _buildEventsMarker(date, events),
              ),
            );
          }
          return children;
        },
      ),
      onDaySelected: (date, events) {
        _onDaySelected(date, events);
        _controller.forward(from: 0.0);
      },
      onVisibleDaysChanged: _onVisibleDaysChanged,
    );
  }

  Widget _buildEventList() {
    if(_selectedEvents != null) {
      return ListView(
        children: _selectedEvents.map((event) => _buildListTile(event)).toList(),
      );
    }
    else {
      return Container();
    }

  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Utils.isSameDay(date, _selectedDay)
            ? Colors.black
            : Utils.isSameDay(date, DateTime.now())
            ? Colors.black
            : Theme.of(context).primaryColor,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: Utils.isSameDay(date, _selectedDay)
                ? Colors.white
                : Utils.isSameDay(date, DateTime.now())
                ? Colors.white
                : Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(CalendarAPI.Event event) {
    return Container(
        margin: EdgeInsets.only(bottom: 1),
        decoration: new BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: event.start.dateTime.isAfter(DateTime.now())
                    ? Theme.of(context).primaryColor
                    : (event.end.dateTime.isAfter(DateTime.now())
                    ? Theme.of(context).primaryColor
                    : Colors.grey[400]),
                blurRadius: 0.5)
          ],
          color: event.start.dateTime.isAfter(DateTime.now())
              ? Colors.white
              : (event.end.dateTime.isAfter(DateTime.now())
              ? Theme.of(context).primaryColor.withAlpha(80)
              : Colors.grey[350]),
          border: new Border(
            bottom: new BorderSide(
                color: Colors.black12, width: 1.0, style: BorderStyle.solid),
          ),
        ),
        child: ListTile(
          title: Text(
            event.summary.toString(),
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(_formatTimeInterval(event)),
        ));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor)));
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  /*

  Methods

  */

  void _onVisibleDaysChanged(
      DateTime first, DateTime last, CalendarFormat format) {
    setState(() {
      _visibleEvents = Map.fromEntries(
        _events.entries.where(
              (entry) =>
          entry.key.isAfter(first.subtract(const Duration(days: 1))) &&
              entry.key.isBefore(last.add(const Duration(days: 1))),
        ),
      );
    });
  }

  void _onDaySelected(DateTime day, List events) {
    setState(() {
      _selectedDay = day;
      _selectedEvents = events;
    });
  }

  String _formatTimeInterval(CalendarAPI.Event event) {

    return sprintf('%02d.%02d - %02d.%02d', [
      event.start.dateTime.toLocal().hour,
      event.start.dateTime.toLocal().minute,
      event.end.dateTime.toLocal().hour,
      event.end.dateTime.toLocal().minute
    ]);
  }

  Future<bool> _updateCalendar() async {
    try {
      var calendarMap = await calendarsService.retrieveEvents(_user);

      if (calendarMap != null) {
        setState(() {
          _events = calendarMap;
          _visibleEvents = _events;
          _selectedDay = DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day);
          _selectedEvents = _events[_selectedDay] ?? [];
          _isLoading = false;
        });
      }
      else {
        setState(() {
          _selectedEvents = [];
          _isLoading = false;
        });
      }

      return Future.value(true);
    } catch (error) {
      print(error.toString());
    }

    return Future.value(false);
  }

  Future<bool> _refreshCalendar() {
    return _updateCalendar();
  }
}


