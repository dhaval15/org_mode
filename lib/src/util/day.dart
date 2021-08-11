import 'hash_utils.dart';

class Day implements Comparable<Day> {
  final int year, month, day;

  const Day(this.day, this.month, this.year);

  static const none = Day(-1, -1, -1);

  factory Day.fromDate(DateTime date) => Day(date.day, date.month, date.year);

  factory Day.fromString(String text) {
    if (text == 'none') return Day.none;
    final day = int.parse(text.substring(0, 2));
    final month = int.parse(text.substring(2, 4));
    final year = int.parse(text.substring(4));
    return Day(day, month, year);
  }

  factory Day.today() {
    final date = DateTime.now();
    return Day(date.day, date.month, date.year);
  }

  DateTime toDate() => DateTime(year, month, day);

  @override
  String toString() => isNone ? 'none' : '$dayText$monthText$yearText';

  String get yearText => year.toString();
  String get monthText => month < 10 ? '0$month' : month.toString();
  String get dayText => day < 10 ? '0$day' : day.toString();

  String get weekday {
    final _weekday = DateTime(year, month, day).weekday;
    switch (_weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
    }
    throw '';
  }

  String get weekdayShort => weekday.substring(0, 3);

  String get monthName {
    switch (month) {
      case DateTime.january:
        return 'January';
      case DateTime.february:
        return 'February';
      case DateTime.march:
        return 'March';
      case DateTime.april:
        return 'April';
      case DateTime.may:
        return 'May';
      case DateTime.june:
        return 'June';
      case DateTime.july:
        return 'July';
      case DateTime.august:
        return 'August';
      case DateTime.september:
        return 'September';
      case DateTime.october:
        return 'October';
      case DateTime.november:
        return 'November';
      case DateTime.december:
        return 'December';
    }
    throw '';
  }

  bool get isNone => this == Day.none;

  bool operator ==(Object other) {
    if (other is Day)
      return other.day == day &&
          other.month == month &&
          other.year == other.year;
    return false;
  }

  @override
  int compareTo(Day other) {
    return toString().compareTo(other.toString());
  }

  @override
  int get hashCode => hashValues(day, month, year);
}

class Time implements Comparable<Time> {
  final int hour, minute;

  const Time(this.hour, this.minute);

  static const none = Time(-1, -1);

  factory Time.fromDuration(Duration duration) =>
      Time(duration.inHours, duration.inMinutes - (duration.inHours * 60));

  factory Time.fromString(String text) {
    if (text == 'none') return Time.none;
    final hour = int.parse(text.substring(0, 2));
    final minute = int.parse(text.substring(2, 4));
    return Time(hour, minute);
  }

  factory Time.now() {
    final date = DateTime.now();
    return Time(date.hour, date.minute);
  }

  bool operator ==(Object other) {
    if (other is Time) return other.hour == hour && other.minute == minute;
    return false;
  }

  Time operator +(Time other) {
    final totalMinutes = minute + other.minute;
    final hours = this.hour + other.hour + (totalMinutes ~/ 60);
    final minutes = totalMinutes % 60;
    return Time(hours, minutes);
  }

  Time operator -(Time other) {
    var minutes = this.minute - other.minute;
    var hours = this.hour - other.hour;
    if (hours < 0) hours = 24 + hours;
    if (minutes < 0) {
      hours = hours - 1;
      minutes = 60 + minutes;
    }
    return Time(hours, minutes);
  }

  String get durationText {
    if (hour == 0) return '${minute}m';
    if (minute == 0) return '${hour}h';
    return '${hour}h ${minute}m';
  }

  bool get isNone => this == Time.none;

  Duration get duration => Duration(hours: hour, minutes: minute);

  int get inMinutes => (hour * 60) + minute;

  @override
  String toString() => isNone ? 'none' : '$hourText$minuteText';

  String get h {
    if (hour == 0) return '12';
    if (hour <= 12) return '$hour';
    return '${hour - 12}';
  }

  String get text {
    if (isNone) return '';
    if (hour == 0) return '12:$minute AM';
    if (hour < 12) return '$hour:$minuteText AM';
    if (hour == 12) return '$hour:$minuteText PM';
    return '${hour - 12}:$minuteText PM';
  }

  String get hourText => hour < 10 ? '0$hour' : hour.toString();
  String get minuteText => minute < 10 ? '0$minute' : minute.toString();

  @override
  int compareTo(Time other) {
    return toString().compareTo(other.toString());
  }

  @override
  int get hashCode => hashValues(hour, minute);
}
