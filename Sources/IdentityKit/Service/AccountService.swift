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
}

@MainActor
@Observable
final public class AccountService {
  public static let shared = AccountService()

  private init() { }

  deinit { }

  public func deleteAccount() async throws {
    guard let user = Auth.auth().currentUser else {
      throw AuthenticationError.invalidCredentials
    }

    let operation: DeleteUserOperation = if user.isAppleIDUser {
      AppleDeleteUserOperation()
    }
    else {
      EmailPasswordDeleteUserOperation()
    }

    do {
      try await operation(on: user)
    }
    catch {
      throw AuthenticationError.userDeletionFailed(underlying: error)
    }
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
  }
}

protocol DeleteUserOperation: AuthenticatedOperation { }

extension DeleteUserOperation {
  func performOperation(on user: User, with token: AuthenticationToken? = nil) async throws {
    try await user.delete()
  }
}
