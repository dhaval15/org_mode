String times(String text, int count) {
  final buffer = StringBuffer();
  while (count > 0) {
    buffer.write(text);
    count--;
  }
  return buffer.toString();
}

List<String> collectTodoKeywords(String text) {
  final list = <String>[];
  final splits = text.trim().split(RegExp('\\s+'));
  for (final split in splits) {
    if (split != '|') list.add(split.split('(').first);
  }
  return list.isNotEmpty ? list : ['TODO', 'DONE'];
}
