void main() {
  String name = 'Data Mining and Business Intelligence (DMBI)';
  String cleaned = name.trim();
  final words = cleaned.split(' ');
  final lowerCaseWords = ['and', 'or', 'for', 'in', 'of', 'to', 'with', 'a', 'an', 'the'];
  
  String res = words.asMap().entries.map((entry) {
    final idx = entry.key;
    final word = entry.value;
    if (word.isEmpty) return '';
    final lowerWord = word.toLowerCase();
    if (idx > 0 && idx < words.length - 1 && lowerCaseWords.contains(lowerWord)) {
      return lowerWord;
    }
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
  
  print(res);
}
