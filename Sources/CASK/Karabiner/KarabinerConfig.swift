import Foundation

struct KarabinerConfig: Codable {
  let global: Global?
  let profiles: [Profile]

  struct Global: Codable {
    let profileName: String?

    enum CodingKeys: String, CodingKey {
      case profileName = "profile_name"
    }
  }

  struct Profile: Codable {
    let name: String
    let complexModifications: ComplexModifications?

    enum CodingKeys: String, CodingKey {
      case name
      case complexModifications = "complex_modifications"
    }
  }

  struct ComplexModifications: Codable {
    let rules: [Rule]
  }

  struct Rule: Codable {
    let description: String?
    let manipulators: [Manipulator]?
  }

  struct Manipulator: Codable {
    let type: String?
    let from: FromEvent?
    let conditions: [Condition]?
    let to: [ToEvent]?
    let toIfAlone: [ToEvent]?
    let toIfHeldDown: [ToEvent]?
    let toAfterKeyUp: [ToEvent]?
    let toDelayedAction: DelayedAction?

    enum CodingKeys: String, CodingKey {
      case type, from, conditions, to
      case toIfAlone = "to_if_alone"
      case toIfHeldDown = "to_if_held_down"
      case toAfterKeyUp = "to_after_key_up"
      case toDelayedAction = "to_delayed_action"
    }
  }

  struct FromEvent: Codable {
    let keyCode: String?
    let modifiers: Modifiers?
    let simultaneous: [FromEvent]?
    let simultaneousOptions: SimultaneousOptions?

    enum CodingKeys: String, CodingKey {
      case keyCode = "key_code"
      case modifiers
      case simultaneous
      case simultaneousOptions = "simultaneous_options"
    }

    init(
      keyCode: String? = nil,
      modifiers: Modifiers? = nil,
      simultaneous: [FromEvent]? = nil,
      simultaneousOptions: SimultaneousOptions? = nil
    ) {
      self.keyCode = keyCode
      self.modifiers = modifiers
      self.simultaneous = simultaneous
      self.simultaneousOptions = simultaneousOptions
    }
  }

  struct SimultaneousOptions: Codable {
    let detectKeyDownUnordered: Bool?

    enum CodingKeys: String, CodingKey {
      case detectKeyDownUnordered = "detect_key_down_unordered"
    }
  }

  struct Modifiers: Codable {
    let mandatory: [String]?
    let optional: [String]?
  }

  struct Condition: Codable {
    let type: String?
    let bundleIdentifiers: [String]?
    let name: String?
    let value: Int?
    let description: String?

    enum CodingKeys: String, CodingKey {
      case type
      case bundleIdentifiers = "bundle_identifiers"
      case name, value, description
    }

    init(
      type: String? = nil,
      bundleIdentifiers: [String]? = nil,
      name: String? = nil,
      value: Int? = nil,
      description: String? = nil
    ) {
      self.type = type
      self.bundleIdentifiers = bundleIdentifiers
      self.name = name
      self.value = value
      self.description = description
    }
  }

  struct ToEvent: Codable {
    let keyCode: String?
    let consumerKeyCode: String?
    let shellCommand: String?
    let setVariable: SetVariable?
    let modifiers: [String]?
    let lazy: Bool?
    let `repeat`: Bool?

    enum CodingKeys: String, CodingKey {
      case keyCode = "key_code"
      case consumerKeyCode = "consumer_key_code"
      case shellCommand = "shell_command"
      case setVariable = "set_variable"
      case modifiers, lazy
      case `repeat` = "repeat"
    }
  }

  struct SetVariable: Codable {
    let name: String?
    let value: Int?
  }

  struct DelayedAction: Codable {
    let toIfInvoked: [ToEvent]?
    let toIfCanceled: [ToEvent]?

    enum CodingKeys: String, CodingKey {
      case toIfInvoked = "to_if_invoked"
      case toIfCanceled = "to_if_canceled"
    }
  }

  var selectedProfile: Profile? {
    let selectedName = global?.profileName
    if let selectedName,
       let profile = profiles.first(where: { $0.name == selectedName }) {
      return profile
    }
    return profiles.first
  }
}

extension KarabinerConfig.Condition: Hashable {}
