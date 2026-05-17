//
// PasswordPolicy.swift
// IdentityKit
//
// Created by Peter Friese on 15.05.26
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

public struct PasswordPolicy: Sendable {
  public let minLength: Int
  public let maxLength: Int
  public let requireUppercase: Bool
  public let requireLowercase: Bool
  public let requireNumeric: Bool
  public let requireNonAlphanumeric: Bool

  public init(
    minLength: Int = 8,
    maxLength: Int = 30,
    requireUppercase: Bool = true,
    requireLowercase: Bool = true,
    requireNumeric: Bool = true,
    requireNonAlphanumeric: Bool = true
  ) {
    self.minLength = minLength
    self.maxLength = maxLength
    self.requireUppercase = requireUppercase
    self.requireLowercase = requireLowercase
    self.requireNumeric = requireNumeric
    self.requireNonAlphanumeric = requireNonAlphanumeric
  }

  public static let standard = PasswordPolicy(
    minLength: 8,
    maxLength: 30,
    requireUppercase: true,
    requireLowercase: true,
    requireNumeric: true,
    requireNonAlphanumeric: true
  )

  public static let firebaseDefault = PasswordPolicy(
    minLength: 6,
    maxLength: 30,
    requireUppercase: false,
    requireLowercase: false,
    requireNumeric: false,
    requireNonAlphanumeric: false
  )
}

public struct PasswordValidationResult: Sendable {
  public let isValid: Bool
  public let missingRequirements: [PasswordRequirement]

  public init(isValid: Bool, missingRequirements: [PasswordRequirement] = []) {
    self.isValid = isValid
    self.missingRequirements = missingRequirements
  }
}

public enum PasswordRequirement: String, CaseIterable, Sendable {
  case minLength
  case maxLength
  case uppercase
  case lowercase
  case numeric
  case nonAlphanumeric
}

public struct PasswordValidator: Sendable {
  private let policy: PasswordPolicy

  public init(policy: PasswordPolicy = .standard) {
    self.policy = policy
  }

  public func validate(_ password: String) -> PasswordValidationResult {
    var missingRequirements: [PasswordRequirement] = []

    if password.count < policy.minLength {
      missingRequirements.append(.minLength)
    }

    if password.count > policy.maxLength {
      missingRequirements.append(.maxLength)
    }

    if policy.requireUppercase && !password.contains(where: { $0.isUppercase }) {
      missingRequirements.append(.uppercase)
    }

    if policy.requireLowercase && !password.contains(where: { $0.isLowercase }) {
      missingRequirements.append(.lowercase)
    }

    if policy.requireNumeric && !password.contains(where: { $0.isNumber }) {
      missingRequirements.append(.numeric)
    }

    if policy.requireNonAlphanumeric && !password.contains(where: { !$0.isLetter && !$0.isNumber }) {
      missingRequirements.append(.nonAlphanumeric)
    }

    return PasswordValidationResult(
      isValid: missingRequirements.isEmpty,
      missingRequirements: missingRequirements
    )
  }

  public func description(for requirement: PasswordRequirement) -> String {
    switch requirement {
    case .minLength:
      return "at least \(policy.minLength) characters"
    case .maxLength:
      return "no more than \(policy.maxLength) characters"
    case .uppercase:
      return "an uppercase letter"
    case .lowercase:
      return "a lowercase letter"
    case .numeric:
      return "a number"
    case .nonAlphanumeric:
      return "a special character"
    }
  }

  public static func requirements(for policy: PasswordPolicy) -> [PasswordRequirement] {
    var requirements: [PasswordRequirement] = [.minLength]

    if policy.requireUppercase {
      requirements.append(.uppercase)
    }
    if policy.requireLowercase {
      requirements.append(.lowercase)
    }
    if policy.requireNumeric {
      requirements.append(.numeric)
    }
    if policy.requireNonAlphanumeric {
      requirements.append(.nonAlphanumeric)
    }

    return requirements
  }
}