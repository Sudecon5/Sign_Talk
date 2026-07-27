class GlossParser {
  // English filler words that aren't signed explicitly
  static const Set<String> _stopWords = {
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 
    'be', 'been', 'to', 'of', 'in', 'at', 'it', 'do', 'does'
  };

  /// Takes spoken transcript text and returns clean sign keywords
  static List<String> parseToKeywords(String transcript) {
    if (transcript.trim().isEmpty) return [];

    // 1. Convert to lowercase and strip special punctuation
    final cleanText = transcript
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '');

    // 2. Split text into individual words
    final words = cleanText.split(RegExp(r'\s+'));

    // 3. Filter out filler stop-words
    return words.where((word) => !_stopWords.contains(word)).toList();
  }
}