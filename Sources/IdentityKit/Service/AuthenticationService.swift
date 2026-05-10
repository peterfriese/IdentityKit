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

public enum AuthenticationOperationType: String {
  case signIn
  case signUp
  case deleteAccount
}

public enum AuthenticationMode: CustomStringConvertible {
  case signIn
  case signUp
  case `continue`

  public var description: String {
    switch self {
    case .signIn:
      return "Sign in"
    case .signUp:
      return "Sign up"
    case .continue:
      return "Continue"
    }
  }
}

public enum AuthenticationState {
  case unauthenticated
  case authenticating
  case authenticated
}

@available(macOS 14.0, *)
@MainActor
@Observable
final public class AuthenticationService {
  public static let shared = AuthenticationService()
  
  @ObservationIgnored
  private nonisolated(unsafe) var _authStateHandle: AuthStateDidChangeListenerHandle?
  
  private init() {
    setupAuthenticationListener()
    signInGuestAccount()
  }
  
  nonisolated deinit {
    if let handle = _authStateHandle {
      Auth.auth().removeStateDidChangeListener(handle)
    }
  }
  
  private func setupAuthenticationListener() {
    _authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.currentUser = user
      self?.updateAuthenticationState()
    }
  }

  func signInGuestAccount() {
    if Auth.auth().currentUser == nil {
      Auth.auth().signInAnonymously()
    }
  }

  func updateAuthenticationState() {
    authenticationState =
      (currentUser == nil || currentUser?.isAnonymous == true)
        ? .unauthenticated
        : .authenticated
  }

  public var authenticationState: AuthenticationState = .unauthenticated

  public var isAuthenticated: Bool {
    authenticationState == .authenticated
  }

  public var currentUser: User?

  public var isGuestAccount: Bool {
    guard let currentUser else { return false }
    return currentUser.isAnonymous
  }

  var errorMessage = ""

  public static func enableKeychainSharing(with group: String) throws {
    try Auth.auth().useUserAccessGroup(group)
  }

  public func signOut() throws {
    try Auth.auth().signOut()
    signInGuestAccount()
  }

  func signIn(with credentials: AuthCredential) async throws {
    try await Auth.auth().signIn(with: credentials)
    updateAuthenticationState()
  }

  func signUp(with credentials: AuthCredential) async throws {
    try await Auth.auth().signIn(with: credentials)
    updateAuthenticationState()
  }

  func link(with credentials: AuthCredential) async throws {
    if let currentUser {
      try await currentUser.link(with: credentials)
      updateAuthenticationState()
    }
  }
}
