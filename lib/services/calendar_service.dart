import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as CalendarAPI;

import 'package:calendar_poc/models/user.dart';

class CalendarService {

  Future<Map<DateTime, List<dynamic>>> retrieveEvents(User user) async {

    List<CalendarAPI.Event> calendarEvents = [];

    String query = 'https://www.googleapis.com/calendar/v3/calendars/' + user.email + '/events?singleEvents=true&timeMax=' + DateTime(DateTime.now().year + 1).toIso8601String().split('.')[0] + 'Z';
    var eventsQuery = await http.get(query, headers: {HttpHeaders.authorizationHeader: "Bearer " + user.accessToken});

    if(eventsQuery == null || eventsQuery.body == null) {
      throw new CustomException(cause: "Nu s-a putut comunica cu serverul, va rugam reincercati.");
    } else {
      List<dynamic> eventsList = json.decode(eventsQuery.body)['items'];

      eventsList.forEach( (event) => calendarEvents.add(CalendarAPI.Event.fromJson(event)));

      if (calendarEvents.length > 0) {
        Map<DateTime, List<dynamic>> calendarMap = new Map();
        calendarEvents.forEach((CalendarAPI.Event event) {


          if(event != null && event.start != null && event.start.dateTime != null) {
            if(calendarMap[DateTime(event.start.dateTime.year, event.start.dateTime.month, event.start.dateTime.day)] == null) {
              calendarMap[DateTime(event.start.dateTime.year, event.start.dateTime.month, event.start.dateTime.day)] = [];
            }
            calendarMap[DateTime(event.start.dateTime.year, event.start.dateTime.month, event.start.dateTime.day)].add(event);
          }
        });

        return calendarMap;
      }
    }
    return null;

  }
}

final calendarsService = CalendarService();


class CustomException implements Exception {
  String cause;

  CustomException({this.cause});

}
