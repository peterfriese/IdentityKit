//
// AccountService.swift
// IdentityKit
//
// Created by Peter Friese on 26.02.25.
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

import Observation
import AuthenticationServices
@preconcurrency import FirebaseAuth

extension NSError {
  var requiresReauthentication: Bool {
    domain == AuthErrorDomain && code == AuthErrorCode.requiresRecentLogin.rawValue
  }

  var credentialAlreadyInUse: Bool {
    domain == AuthErrorDomain && code == AuthErrorCode.credentialAlreadyInUse.rawValue
  }
}

/// A service for managing user account operations.
///
/// This service provides methods for updating user profile information including
/// display name, email, photo URL, and account deletion. It requires a signed-in user
/// for all operations.
///
/// ## Topics
/// ### Initializers
/// - ``shared``
///
/// ### Properties
/// None
///
/// ### Methods
/// - ``refreshUser()``
/// - ``updateDisplayName(_:)``
/// - ``updateEmail(_:)``
/// - ``updatePhotoURL(_:)``
/// - ``deleteAccount()``
@MainActor
@Observable
final public class AccountService {
  public static let shared = AccountService()

  private let authenticationService = AuthenticationService.shared

  private init() { }

  deinit { }

  public func refreshUser() {
    authenticationService.refreshUser()
  }

  public func updateDisplayName(_ displayName: String) async throws {
    guard let user = Auth.auth().currentUser else {
      throw AuthenticationError.invalidCredentials
    }

    let changeRequest = user.createProfileChangeRequest()
    changeRequest.displayName = displayName.isEmpty ? nil : displayName
    try await changeRequest.commitChanges()
    refreshUser()
  }

  public func updateEmail(_ email: String) async throws {
    guard let user = Auth.auth().currentUser else {
      throw AuthenticationError.invalidCredentials
    }

    do {
      try await user.sendEmailVerification(beforeUpdatingEmail: email)
      refreshUser()
    }
    catch let error as NSError where error.requiresReauthentication {
      throw AuthenticationError.reauthenticationRequired
    }
  }

  public func updatePhotoURL(_ url: URL) async throws {
    guard let user = Auth.auth().currentUser else {
      throw AuthenticationError.invalidCredentials
    }

    let changeRequest = user.createProfileChangeRequest()
    changeRequest.photoURL = url
    try await changeRequest.commitChanges()
    refreshUser()
  }

  public func deleteAccount() async throws {
    guard let user = Auth.auth().currentUser else {
      throw AuthenticationError.invalidCredentials
    }

    #if canImport(UIKit)
    let operation: DeleteUserOperation = if user.isAppleIDUser {
      AppleDeleteUserOperation()
    }
    else {
      EmailPasswordDeleteUserOperation()
    }
    #else
    guard user.isAppleIDUser else {
      throw AuthenticationError.invalidCredentials
    }
    let operation: DeleteUserOperation = AppleDeleteUserOperation()
    #endif
    try await operation(on: user)
  }
}

enum AuthenticationToken {
  case apple(ASAuthorizationAppleIDCredential, String)
  case firebase(String)
}

protocol AuthenticatedOperation {
  func callAsFunction(on user: User) async throws
  func reauthenticate() async throws -> AuthenticationToken
  func performOperation(on user: User, with token: AuthenticationToken?) async throws
}

extension AuthenticatedOperation {
  func callAsFunction(on user: User) async throws {
    do {
      try await performOperation(on: user, with: nil)
    }
    catch let error as NSError where error.requiresReauthentication {
      let token = try await reauthenticate()
      try await performOperation(on: user, with: token)
    }
    catch AuthenticationError.reauthenticationRequired {
      let token = try await reauthenticate()
      try await performOperation(on: user, with: token)
    }
  }
}

protocol DeleteUserOperation: AuthenticatedOperation { }

extension DeleteUserOperation {
  func performOperation(on user: User, with token: AuthenticationToken? = nil) async throws {
    try await user.delete()
  }
}
