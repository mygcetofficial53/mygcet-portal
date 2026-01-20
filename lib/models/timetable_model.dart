
import 'package:flutter/material.dart';

enum WeekDay {
  Monday,
  Tuesday,
  Wednesday,
  Thursday,
  Friday,
  Saturday;

  String get name => toString().split('.').last;
}

class TimeSlot {
  final String subject;
  final String subjectCode;
  final String startTime; // Format: "9:05"
  final String endTime;   // Format: "9:55"
  final String room;
  final bool isLab;
  final String faculty;
  final List<String>? batch; // For labs split by batch (e.g., A1, A2)

  TimeSlot({
    required this.subject,
    this.subjectCode = '',
    required this.startTime,
    required this.endTime,
    this.room = '',
    this.isLab = false,
    this.faculty = '',
    this.batch,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      subject: json['subject'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      room: json['room'] ?? '',
      isLab: json['isLab'] ?? false,
      faculty: json['faculty'] ?? '',
      batch: json['batch'] != null ? List<String>.from(json['batch']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'subjectCode': subjectCode,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'isLab': isLab,
      'faculty': faculty,
      'batch': batch,
    };
  }
}

class Timetable {
  final Map<String, List<TimeSlot>> weekSchedule;

  Timetable({required this.weekSchedule});

  factory Timetable.fromJson(Map<String, dynamic> json) {
    Map<String, List<TimeSlot>> schedule = {};
    json.forEach((key, value) {
      if (value is List) {
        schedule[key] = value.map((e) => TimeSlot.fromJson(e)).toList();
      }
    });
    return Timetable(weekSchedule: schedule);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    weekSchedule.forEach((key, value) {
      json[key] = value.map((e) => e.toJson()).toList();
    });
    return json;
  }
  
  static Timetable empty() {
    return Timetable(weekSchedule: {});
  }
}

class Subject {
  final String name;
  final String code;

  Subject({required this.name, required this.code});

  Map<String, dynamic> toJson() => {'name': name, 'code': code};

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

class Faculty {
  final String name;
  final String shortName;

  Faculty({required this.name, required this.shortName});

  Map<String, dynamic> toJson() => {'name': name, 'shortName': shortName};

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? '',
    );
  }
}

class TimetableData {
  final Timetable? timetable;
  final List<Subject> subjects;
  final List<Faculty> faculties;

  TimetableData({this.timetable, required this.subjects, required this.faculties});

  Map<String, dynamic> toJson() => {
    'timetable': timetable?.toJson(),
    'subjects': subjects.map((e) => e.toJson()).toList(),
    'faculties': faculties.map((e) => e.toJson()).toList(),
  };

  factory TimetableData.fromJson(Map<String, dynamic> json) {
    return TimetableData(
      timetable: json['timetable'] != null ? Timetable.fromJson(json['timetable']) : null,
      subjects: (json['subjects'] as List?)?.map((e) => Subject.fromJson(e)).toList() ?? [],
      faculties: (json['faculties'] as List?)?.map((e) => Faculty.fromJson(e)).toList() ?? [],
    );
  }
}
