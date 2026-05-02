//
// AccountViewTests.swift
// IdentityKitTests
//
// Created by Peter Friese on 02.05.26
//

import Testing
import SwiftUI
import IdentityKit

@Suite
struct AccountViewTests {
  @Test
  func rendersGuestAccountView() {
    let authService = MockAuthenticationService()
    authService.mockUser = MockUser(isAnonymous: true, isEmailVerified: false)

    let view = AccountView()
      .environment(authService)

    let renderer = view.render()
    #expect(renderer !== nil)
  }

  @Test
  func rendersAuthenticatedAccountView() {
    let authService = MockAuthenticationService()
    authService.mockUser = MockUser(isAnonymous: false, isEmailVerified: true, email: "test@example.com")

    let view = AccountView()
      .environment(authService)

    let renderer = view.render()
    #expect(renderer !== nil)
  }

  @Test
  func showsUpgradeButtonForGuest() {
    let authService = MockAuthenticationService()
    authService.mockUser = MockUser(isAnonymous: true, isEmailVerified: false)

    let view = AccountView()
      .environment(authService)

    let renderer = view.render()
    #expect(renderer?.toString().contains("Upgrade to Full Account") == true)
  }

  @Test
  func showsSignOutButtonForAuthenticated() {
    let authService = MockAuthenticationService()
    authService.mockUser = MockUser(isAnonymous: false, isEmailVerified: true, email: "test@example.com")

    let view = AccountView()
      .environment(authService)

    let renderer = view.render()
    #expect(renderer?.toString().contains("Sign Out") == true)
  }
}

private class MockAuthenticationService: AuthenticationService {
  var mockUser: User?

  override var currentUser: User? {
    mockUser
  }

  override var isGuestAccount: Bool {
    mockUser?.isAnonymous ?? false
  }

  override var isAuthenticated: Bool {
    !(mockUser?.isAnonymous ?? true)
  }
}

private class MockUser: User {
  let mockIsAnonymous: Bool
  let mockIsEmailVerified: Bool
  let mockEmail: String?
  let mockUID: String
  let mockProviderData: [ProviderUserInfo]

  init(isAnonymous: Bool, isEmailVerified: Bool, email: String? = nil, providerData: [ProviderUserInfo] = []) {
    self.mockIsAnonymous = isAnonymous
    self.mockIsEmailVerified = isEmailVerified
    self.mockEmail = email
    self.mockUID = UUID().uuidString
    self.mockProviderData = providerData
  }

  var isAnonymous: Bool { mockIsAnonymous }
  var isEmailVerified: Bool { mockIsEmailVerified }
  var email: String? { mockEmail }
  var uid: String { mockUID }
  var displayName: String? { nil }
  var photoURL: URL? { nil }
  var emailVerified: Bool { mockIsEmailVerified }
  var providerData: [ProviderUserInfo] { mockProviderData }
  var providerID: String { "firebase" }
  var metadata: UserMetadata { UserMetadata(creationDate: Date(), lastSignInDate: Date()) }

  func getIDTokenResult() async throws -> IDTokenResult { throw CancellationError() }
  func getIDToken() async throws -> String { throw CancellationError() }
  func link(with credential: AuthCredential) async throws -> User { self }
  func unlink(from provider: String) async throws -> User { self }
  func updateEmail(to email: String) async throws {}
  func updatePassword(to password: String) async throws {}
  func updateProfile(displayName: String?, photoURL: URL?) async throws {}
  func sendEmailVerification() async throws {}
  func delete() async throws {}
  func reauthenticate(with credential: AuthCredential) async throws {}
  func getRefreshToken() -> String { "" }
}

private class MockProviderUserInfo: ProviderUserInfo {
  let mockProviderID: String

  init(providerID: String) {
    self.mockProviderID = providerID
  }

  var providerID: String { mockProviderID }
  var displayName: String? { nil }
  var email: String? { nil }
  var phoneNumber: String? { nil }
  var photoURL: URL? { nil }
  var uid: String? { nil }
}