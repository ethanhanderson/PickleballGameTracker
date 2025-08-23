import Foundation
import SharedGameCore

// MARK: - Fuzzy Search Utility

struct FuzzySearchUtility {

  /// Filter game types based on fuzzy search criteria
  static func filterGameTypes(searchText: String) -> [GameType] {
    if searchText.isEmpty {
      return []
    } else {
      // Get all unique game types with fuzzy matching
      let allMatchingTypes = Set(
        GameCatalog.allGameTypes.filter { gameType in
          fuzzyMatch(searchText: searchText, target: gameType.displayName)
            || fuzzyMatch(searchText: searchText, target: gameType.rawValue)
        }
      )

      // Also include game types from sections whose titles match the search
      let sectionsWithMatchingTitles = GameCatalog.sections.filter { section in
        fuzzyMatch(searchText: searchText, target: section.title)
      }

      let typesFromMatchingSections = Set(
        sectionsWithMatchingTitles.flatMap { $0.gameTypes }
      )

      // Combine and sort by match quality
      let combinedTypes = allMatchingTypes.union(typesFromMatchingSections)
      return Array(combinedTypes).sorted { gameType1, gameType2 in
        let score1 = matchScore(searchText: searchText, target: gameType1.displayName)
        let score2 = matchScore(searchText: searchText, target: gameType2.displayName)

        if score1 != score2 {
          return score1 > score2  // Higher scores first
        }
        return gameType1.displayName < gameType2.displayName  // Alphabetical as tiebreaker
      }
    }
  }

  /// Fuzzy matching algorithm that handles partial matches, misspellings, and trailing letters
  private static func fuzzyMatch(searchText: String, target: String) -> Bool {
    let search = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    let targetText = target.lowercased()

    // Empty search matches nothing
    guard !search.isEmpty else { return false }

    // Exact match (highest priority)
    if targetText == search {
      return true
    }

    // Contains match (high priority)
    if targetText.contains(search) {
      return true
    }

    // Prefix match (for partial typing)
    if targetText.hasPrefix(search) {
      return true
    }

    // Fuzzy matching for misspellings and variations
    return levenshteinDistance(search, targetText) <= maxEditDistance(for: search)
  }

  /// Calculate match score for sorting (higher = better match)
  private static func matchScore(searchText: String, target: String) -> Int {
    let search = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    let targetText = target.lowercased()

    // Exact match
    if targetText == search {
      return 1000
    }

    // Starts with search
    if targetText.hasPrefix(search) {
      return 900 - search.count + targetText.count  // Shorter targets ranked higher
    }

    // Contains search
    if targetText.contains(search) {
      let position =
        targetText.range(of: search)?.lowerBound.utf16Offset(in: targetText) ?? targetText.count
      return 800 - position  // Earlier positions ranked higher
    }

    // Fuzzy match based on edit distance
    let distance = levenshteinDistance(search, targetText)
    return max(0, 500 - distance * 50)
  }

  /// Calculate Levenshtein distance between two strings
  private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
    let s1Array = Array(s1)
    let s2Array = Array(s2)
    let s1Count = s1Array.count
    let s2Count = s2Array.count

    // Create matrix
    var matrix = Array(repeating: Array(repeating: 0, count: s2Count + 1), count: s1Count + 1)

    // Initialize first row and column
    for i in 0...s1Count {
      matrix[i][0] = i
    }
    for j in 0...s2Count {
      matrix[0][j] = j
    }

    // Fill matrix
    for i in 1...s1Count {
      for j in 1...s2Count {
        let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
        matrix[i][j] = min(
          matrix[i - 1][j] + 1,  // deletion
          matrix[i][j - 1] + 1,  // insertion
          matrix[i - 1][j - 1] + cost  // substitution
        )
      }
    }

    return matrix[s1Count][s2Count]
  }

  /// Determine maximum edit distance based on search length
  private static func maxEditDistance(for search: String) -> Int {
    let length = search.count
    if length <= 3 {
      return 1  // Allow 1 edit for short words
    } else if length <= 6 {
      return 2  // Allow 2 edits for medium words
    } else {
      return 3  // Allow 3 edits for longer words
    }
  }
}
