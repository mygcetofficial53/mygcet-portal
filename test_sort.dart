void main() {
  final times = ["10:00 AM", "1:25 PM", "9:05 AM", "11:50 AM"];
  print("Original: $times");
  
  times.sort((a, b) => compareTime(a, b));
  
  print("Sorted: $times");
  
  // Debug specific comparison
  print("Compare 10:00 AM vs 9:05 AM: ${compareTime("10:00 AM", "9:05 AM")}");
}

int compareTime(String time1, String time2) {
  final t1 = parseTime(time1);
  final t2 = parseTime(time2);
  
  print("Parsing '$time1' -> $t1");
  print("Parsing '$time2' -> $t2");
  
  if (t1 == null || t2 == null) return 0;
  return t1.compareTo(t2);
}

DateTime? parseTime(String timeStr) {
  try {
    // Mocking the logic directly from the service
    var cleanTime = timeStr.trim().toUpperCase();
    
    if (cleanTime.contains('AM') || cleanTime.contains('PM')) {
       if (!cleanTime.contains(' ')) {
         cleanTime = cleanTime.replaceAllMapped(RegExp(r'(\d+:\d+)([AP]M)'), (m) => '${m[1]} ${m[2]}');
       }
       
       // Simple manual parse for test since we don't have Intl package in this isolated script context easily without pub get, 
       // BUT wait, I have access to dart:core. I'll implement a rough parser to simulate logic or just assume 
       // I can use logic similar to what I wrote.
       // Actually, I can't use 'package:intl' in a standalone script unless it's in pubspec. 
       // The user environment HAS intl.
       // I will attempt simple split logic for this test to verify the "logic flow" not the library.
       
       // Mimicking DateFormat("h:mm a")
       final parts = cleanTime.split(' ');
       final timeParts = parts[0].split(':');
       var hour = int.parse(timeParts[0]);
       final minute = int.parse(timeParts[1]);
       final period = parts[1];
       
       if (period == 'PM' && hour != 12) hour += 12;
       if (period == 'AM' && hour == 12) hour = 0;
       
       final now = DateTime.now();
       return DateTime(now.year, now.month, now.day, hour, minute);
    }
    
    return null;
  } catch (e) {
    print("Error: $e");
    return null;
  }
}
