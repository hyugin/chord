import Foundation

enum RegexMatcher {
  static let maxPatternLength = 256
  private static let matchTimeout: DispatchTimeInterval = .milliseconds(50)

  static func matches(pattern: String, in text: String) -> Bool {
    if pattern.count > maxPatternLength {
      return pattern == text
    }

    guard let regex = try? NSRegularExpression(pattern: pattern) else {
      return pattern == text
    }

    let range = NSRange(text.startIndex..., in: text)
    var result = false
    let semaphore = DispatchSemaphore(value: 0)

    DispatchQueue.global(qos: .userInitiated).async {
      result = regex.firstMatch(in: text, range: range) != nil
      semaphore.signal()
    }

    if semaphore.wait(timeout: .now() + matchTimeout) == .timedOut {
      return false
    }

    return result
  }
}
