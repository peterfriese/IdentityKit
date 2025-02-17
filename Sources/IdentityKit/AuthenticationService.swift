//
// AuthenticationService.swift
// IdentityKit
//
// Created by Peter Friese on 28.01.25.
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

@preconcurrency import FirebaseAuth
import Observation

public enum AuthenticationMode: CustomStringConvertible {
  case signIn
  case signUp
  case `continue`

  public var description: String {
    switch self {
    case .signIn:
      return "Sign in with"
    case .signUp:
      return "Sign up with"
    case .continue:
      return "Continue with"
    }
  }
}

public enum AuthenticationState {
  case unauthenticated
  case authenticating
  case authenticated
}

@MainActor
@Observable
final public class AuthenticationService {
  public var authenticationState: AuthenticationState = .unauthenticated
  public var isAuthenticated: Bool {
    authenticationState == .authenticated
  }
  public var currentUser: User?

  var errorMessage = ""

  private init() {
    setupAuthenticationListener()
  }

  public static func enableKeychainSharing(with group: String) {
    do {
      try Auth.auth().useUserAccessGroup(group)
    } catch let error as NSError {
      print("Error changing user access group: %@", error)
    }
  }

  public static let shared = AuthenticationService()

  private func setupAuthenticationListener() {
    Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.currentUser = user
      self?.authenticationState = user == nil ? .unauthenticated : .authenticated
    }
  }

  public func signOut() throws {
    try Auth.auth().signOut()
  }
}
