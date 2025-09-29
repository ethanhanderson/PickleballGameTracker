import GameTrackerCore
import Foundation

enum GameTypeSearch {

  static func filterGameTypes(searchText: String) -> [GameType] {
    if searchText.isEmpty {
      return []
    } else {
      let allMatchingTypes = Set(
        GameCatalog.allGameTypes.filter { gameType in
          fuzzyMatch(searchText: searchText, target: gameType.displayName)
            || fuzzyMatch(searchText: searchText, target: gameType.rawValue)
        }
      )

      let sectionsWithMatchingTitles = GameCatalog.sections.filter { section in
        fuzzyMatch(searchText: searchText, target: section.title)
      }

      let typesFromMatchingSections = Set(
        sectionsWithMatchingTitles.flatMap { $0.gameTypes }
      )

      let combinedTypes = allMatchingTypes.union(typesFromMatchingSections)
      return Array(combinedTypes).sorted { gameType1, gameType2 in
        let score1 = matchScore(searchText: searchText, target: gameType1.displayName)
        let score2 = matchScore(searchText: searchText, target: gameType2.displayName)

        if score1 != score2 {
          return score1 > score2
        }
        return gameType1.displayName < gameType2.displayName
      }
    }
  }

  private static func fuzzyMatch(searchText: String, target: String) -> Bool {
    let search = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    let targetText = target.lowercased()

    guard !search.isEmpty else { return false }

    if targetText == search { return true }
    if targetText.contains(search) { return true }
    if targetText.hasPrefix(search) { return true }

    return levenshteinDistance(search, targetText) <= maxEditDistance(for: search)
  }

  private static func matchScore(searchText: String, target: String) -> Int {
    let search = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    let targetText = target.lowercased()

    if targetText == search { return 1000 }
    if targetText.hasPrefix(search) { return 900 - search.count + targetText.count }
    if targetText.contains(search) {
      let position =
        targetText.range(of: search)?.lowerBound.utf16Offset(in: targetText) ?? targetText.count
      return 800 - position
    }

    let distance = levenshteinDistance(search, targetText)
    return max(0, 500 - distance * 50)
  }

  private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
    let s1Array = Array(s1)
    let s2Array = Array(s2)
    let s1Count = s1Array.count
    let s2Count = s2Array.count

    var matrix = Array(repeating: Array(repeating: 0, count: s2Count + 1), count: s1Count + 1)

    for i in 0...s1Count { matrix[i][0] = i }
    for j in 0...s2Count { matrix[0][j] = j }

    for i in 1...s1Count {
      for j in 1...s2Count {
        let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
        matrix[i][j] = min(
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        )
      }
    }

    return matrix[s1Count][s2Count]
  }

  private static func maxEditDistance(for search: String) -> Int {
    let length = search.count
    if length <= 3 { return 1 } else if length <= 6 { return 2 } else { return 3 }
  }
}
