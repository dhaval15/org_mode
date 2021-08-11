import 'day.dart';

class Timestamp {
  final Day day;
  final Time time;
  final bool isActive;

  const Timestamp(this.day, this.time, {this.isActive = false});

  Timestamp copyWith({Day? day, Time? time}) => Timestamp(
        day ?? this.day,
        time ?? this.time,
      );

  factory Timestamp.now() {
    final date = DateTime.now();
    return Timestamp(Day.fromDate(date), Time(date.hour, date.minute));
  }

  @override
  String toString() {
    return day.weekdayShort + ' => ' + time.text;
  }

  String toOrg() {
    final opening = isActive ? '<' : '[';
    final closing = isActive ? '>' : ']';
    return day.isNone
        ? ''
        : time.isNone
            ? '$opening${day.yearText}-${day.monthText}-${day.dayText} ${day.weekdayShort}$closing'
            : '$opening${day.yearText}-${day.monthText}-${day.dayText} ${day.weekdayShort} ${time.hourText}:${time.minuteText}$closing';
  }

  static const none = Timestamp(Day.none, Time.none);
}
