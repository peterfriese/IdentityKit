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
import os

private let authLogger = Logger(subsystem: "dev.peterfriese.identitykit", category: "AuthenticationService")

/// The type of authentication operation being performed.
///
/// This enum is used to track the current authentication operation type
/// for logging and analytics purposes.
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

/// The current authentication mode for the authentication flow.
///
/// This determines what type of authentication UI to display and what
/// validation rules to apply.
public enum AuthenticationState {
  case unauthenticated
  case authenticating
  case authenticated
}

/// The main authentication service for IdentityKit.
///
/// This service manages user authentication state, provides methods for signing in,
/// signing up, and linking accounts with various identity providers. It integrates
/// with Firebase Authentication and supports Apple, Google, and email/password authentication.
///
/// ## Topics
/// ### Initializers
/// - ``init()``
/// - ``shared``
///
/// ### Properties
/// - ``authenticationState``
/// - ``isAuthenticated``
/// - ``currentUser``
/// - ``userDisplayName``
/// - ``userEmail``
/// - ``userPhotoURL``
/// - ``userIsEmailVerified``
/// - ``userIsAnonymous``
/// - ``isGuestAccount``
///
/// ### Methods
/// - ``refreshUser()``
/// - ``signOut()``
/// - ``enableKeychainSharing(with:)``
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
      Task { @MainActor in
        let userId = user?.uid ?? "nil"
        let isAnon = user?.isAnonymous ?? false
        authLogger.debug("Auth listener triggered - user: \(userId), isAnonymous: \(isAnon)")
        self?.currentUser = user
        self?.syncUserProperties()
        self?.updateAuthenticationState()
      }
    }
  }

  private func syncUserProperties() {
    userDisplayName = currentUser?.displayName
    userEmail = currentUser?.email
    userPhotoURL = currentUser?.photoURL
    userIsEmailVerified = currentUser?.isEmailVerified ?? false
    userIsAnonymous = currentUser?.isAnonymous ?? false

    let displayName = currentUser?.displayName
    let email = currentUser?.email
    let photoURL = currentUser?.photoURL
    let isEmailVerified = currentUser?.isEmailVerified ?? false
    let isAnonymous = currentUser?.isAnonymous ?? false
    authLogger.debug("Synced user properties - displayName: \(String(describing: displayName)), email: \(String(describing: email)), photoURL: \(String(describing: photoURL)), isEmailVerified: \(isEmailVerified), isAnonymous: \(isAnonymous)")
  }

  public func refreshUser() {
    currentUser = Auth.auth().currentUser
    syncUserProperties()
  }

  func signInGuestAccount() {
    authLogger.debug("signInGuestAccount called - currentUser: \(String(describing: Auth.auth().currentUser))")
    if Auth.auth().currentUser == nil {
      authLogger.info("No current user, signing in anonymously")
      Auth.auth().signInAnonymously()
    } else {
      authLogger.debug("Current user exists, not signing in anonymously - isAnonymous: \(Auth.auth().currentUser?.isAnonymous ?? false)")
    }
  }

  func updateAuthenticationState() {
    let wasAuthenticated = authenticationState == .authenticated
    authenticationState =
      (currentUser == nil || currentUser?.isAnonymous == true)
        ? .unauthenticated
        : .authenticated

    let isAuthenticated = authenticationState == .authenticated
    let userUID = currentUser?.uid ?? "unknown"
    let providerIDs = currentUser?.providerData.map { $0.providerID } ?? []

    if !wasAuthenticated && isAuthenticated {
      authLogger.info("User authenticated - uid: \(userUID), providers: \(providerIDs)")
    } else if wasAuthenticated && !isAuthenticated {
      authLogger.info("User unauthenticated")
    }
  }

  public var authenticationState: AuthenticationState = .unauthenticated

  public var isAuthenticated: Bool {
    authenticationState == .authenticated
  }

  public var currentUser: User?

  public var userDisplayName: String?
  public var userEmail: String?
  public var userPhotoURL: URL?
  public var userIsEmailVerified: Bool = false
  public var userIsAnonymous: Bool = false

  public var isGuestAccount: Bool {
    userIsAnonymous
  }

  var errorMessage = ""

  public static func enableKeychainSharing(with group: String) throws {
    try Auth.auth().useUserAccessGroup(group)
  }

  public func signOut() throws {
    authLogger.debug("signOut called")
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