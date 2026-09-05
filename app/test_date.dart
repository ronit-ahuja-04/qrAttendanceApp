void main() {
  final d = DateTime(2026, 9, 1);
  print(d.toIso8601String());
  print(d.toUtc().toIso8601String());
}
