//
//  AccountView.swift
//  IdentityKit
//
//  Created by Peter Friese on 02.05.26
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import SwiftUI
import os.log

@MainActor
public struct AccountView: View {
  @Environment(AuthenticationService.self) private var authenticationService
  @Environment(\.dismiss) private var dismiss

  private var authenticationProviders: [AuthenticationProvider]
  private var onUpgradeFailed: ((Error) -> Void)?
  private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "AccountView")

  @State private var presentingAuthenticationScreen = false
  @State private var presentingDeleteConfirmation = false
  @State private var isSigningOut = false
  @State private var wasGuestBeforeUpgrade = false

  public init(
    authenticationProviders: [AuthenticationProvider] = [.email, .apple, .google],
    onUpgradeFailed: ((Error) -> Void)? = nil
  ) {
    self.authenticationProviders = authenticationProviders
    self.onUpgradeFailed = onUpgradeFailed
  }

  private var isGuest: Bool {
    authenticationService.isGuestAccount
  }

  private var isAuthenticated: Bool {
    authenticationService.isAuthenticated
  }

  private var userDisplayName: String? {
    authenticationService.currentUser?.displayName
  }

  private var userEmail: String? {
    authenticationService.currentUser?.email
  }

  private var userPhotoURL: URL? {
    authenticationService.currentUser?.photoURL
  }

  private var isEmailVerified: Bool {
    authenticationService.currentUser?.isEmailVerified ?? false
  }

  private func handleUpgrade() async {
    wasGuestBeforeUpgrade = isGuest
    presentingAuthenticationScreen = true
  }

  private func handleAuthenticationScreenDismiss() {
    if wasGuestBeforeUpgrade && isGuest {
      onUpgradeFailed?(AuthenticationError.upgradeCancelled)
    }
    wasGuestBeforeUpgrade = false
  }

  private func handleSignOut() async {
    isSigningOut = true
    defer { isSigningOut = false }
    do {
      try authenticationService.signOut()
      dismiss()
    } catch {
      logger.error("Sign out failed: \(error.localizedDescription)")
    }
  }

  private func handleDeleteAccount() async {
    do {
      try await AccountService.shared.deleteAccount()
      dismiss()
    } catch {
      logger.error("Account deletion failed: \(error.localizedDescription)")
    }
  }

  public var body: some View {
    NavigationStack {
      List {
        if isAuthenticated {
          accountHeaderSection
          Section {
            NavigationLink {
              PersonalInformationView()
                .environment(authenticationService)
            } label: {
              Label("Personal Information", systemImage: "person.text.rectangle")
            }

            NavigationLink {
              SignInSecurityView()
                .environment(authenticationService)
            } label: {
              Label("Sign-In & Security", systemImage: "key.fill")
            }
          }
          dangerZoneSection
        } else {
          guestSection
        }
      }
      .platform.listStyle(.insetGrouped)
      .navigationTitle("Account")
      .platform.navigationBarTitleDisplayMode(.inline)
      .toolbar {
        #if os(iOS)
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
          } label: {
            Label("Close", systemImage: "xmark")
          }
        }
        #else
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Label("Close", systemImage: "xmark")
          }
        }
        #endif
      }
      .sheet(isPresented: $presentingAuthenticationScreen, onDismiss: handleAuthenticationScreenDismiss) {
        AuthenticationScreen()
          .environment(authenticationService)
          .authenticationProviders(authenticationProviders)
      }
      .sheet(isPresented: $presentingDeleteConfirmation) {
        AccountDeletionConfirmationDialog {
          Task {
            await handleDeleteAccount()
          }
        }
      }
    }
  }

  @ViewBuilder
  private var accountHeaderSection: some View {
    VStack(spacing: 8) {
      if let photoURL = userPhotoURL {
        AsyncImage(url: photoURL) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          case .failure, .empty:
            placeholderAvatar
          @unknown default:
            placeholderAvatar
          }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
      } else {
        placeholderAvatar
      }

      if let displayName = userDisplayName, !displayName.isEmpty {
        Text(displayName)
          .font(.title2)
          .fontWeight(.bold)
      } else if let email = userEmail {
        Text(email)
          .font(.title2)
          .fontWeight(.bold)
      }

      if let email = userEmail, userDisplayName != nil && !userDisplayName!.isEmpty {
        Text(email)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
    .listRowBackground(Color.clear)
    .padding(.vertical, 16)
  }

  private var placeholderAvatar: some View {
    Image(systemName: "person.fill")
      .font(.system(size: 40))
      .foregroundStyle(.secondary)
      .frame(width: 80, height: 80)
      .background(Color.gray.opacity(0.2))
      .clipShape(Circle())
  }

  @ViewBuilder
  private var dangerZoneSection: some View {
    Section {
      Button(role: .destructive) {
        Task { await handleSignOut() }
      } label: {
        Group {
          if isSigningOut {
            ProgressView()
          } else {
            Text("Sign Out")
              .fontWeight(.medium)
          }
        }
        .frame(maxWidth: .infinity, alignment: .center)
      }
      .disabled(isSigningOut)
    }

    Section {
      Button(role: .destructive) {
        presentingDeleteConfirmation = true
      } label: {
        Text("Delete Account")
          .fontWeight(.medium)
        .frame(maxWidth: .infinity, alignment: .center)
      }
    } footer: {
      Text("This action cannot be undone.")
        .font(.caption)
    }
  }

  @ViewBuilder
  private var guestSection: some View {
    VStack(spacing: 24) {
      Image(systemName: "person.fill.questionmark")
        .font(.system(size: 60))
        .foregroundStyle(.orange)
        .padding(.top, 40)

      VStack(spacing: 8) {
        Text("Guest Account")
          .font(.title2)
          .fontWeight(.bold)

        Text("Your data is stored on this device only")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      VStack(alignment: .leading, spacing: 12) {
        Text("Upgrade to a full account to:")
          .font(.subheadline)
          .fontWeight(.medium)

        VStack(alignment: .leading, spacing: 8) {
          Label("Sync data across devices", systemImage: "iphone.and.arrow.forward")
          Label("Recover your account with email", systemImage: "envelope.fill")
          Label("Access your account from any device", systemImage: "globe")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal)

      Spacer()

      Button {
        Task { await handleUpgrade() }
      } label: {
        Text("Upgrade to Full Account")
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
      }
      .buttonStyle(.borderedProminent)
      .padding(.horizontal)
      .padding(.bottom, 32)
    }
  }
}

#Preview("Guest") {
  AccountView()
    .environment(AuthenticationService.shared)
}

#Preview("Authenticated") {
  AccountView()
    .environment(AuthenticationService.shared)
}
