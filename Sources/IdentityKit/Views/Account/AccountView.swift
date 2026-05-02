//
// AccountView.swift
// IdentityKit
//
// Created by Peter Friese on 02.05.26
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

import SwiftUI

public struct AccountView: View {
  @State private var showAuthenticationScreen = false
  @State private var showDeleteConfirmation = false
  @State private var deleteError: Error?

  private var authService: AuthenticationService {
    AuthenticationService.shared
  }

  public init() {}

  public var body: some View {
    List {
      accountStatusSection
      authenticationActionsSection
      accountManagementSection
    }
    .navigationTitle("Account")
    .sheet(isPresented: $showAuthenticationScreen) {
      AuthenticationScreen()
        .authenticationProviders([.email, .apple, .google])
    }
    .sheet(isPresented: $showDeleteConfirmation) {
      AccountDeletionConfirmationDialog {
        Task {
          do {
            try await AccountService.shared.deleteAccount()
          } catch {
            deleteError = error
          }
        }
      }
    }
    .alert("Account Deletion Failed", isPresented: .init(
      get: { deleteError != nil },
      set: { if !$0 { deleteError = nil } }
    )) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(deleteError?.localizedDescription ?? "An error occurred")
    }
  }
}

extension AccountView {
  @ViewBuilder
  private var accountStatusSection: some View {
    Section("Current Account") {
      if authService.isGuestAccount {
        guestAccountView
      } else if authService.isAuthenticated {
        authenticatedAccountView
      } else {
        unauthenticatedView
      }
    }
  }

  private var guestAccountView: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "person.fill.questionmark")
          .foregroundStyle(.orange)
        Text("Guest Account")
          .font(.headline)
      }

      Text("Your guest account is tied to this device. If you switch devices without upgrading to a full account, you may lose access to your data.")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Text("Benefits of upgrading to a full account:")
        .font(.subheadline)
        .padding(.top, 8)

      VStack(alignment: .leading, spacing: 4) {
        Label("Sync across devices", systemImage: "icloud")
        Label("Data backup and recovery", systemImage: "externaldrive")
        Label("Access on other devices", systemImage: "iphone")
      }
      .font(.caption)
      .foregroundStyle(.secondary)

      Button {
        showAuthenticationScreen = true
      } label: {
        Text("Upgrade to Full Account")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .padding(.top, 8)
    }
    .padding(.vertical, 8)
  }

  private var authenticatedAccountView: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "person.fill")
          .foregroundStyle(.green)
        Text("Full Account")
          .font(.headline)
      }

      if let email = authService.currentUser?.email {
        HStack {
          Text(email)
            .font(.subheadline)
            .foregroundStyle(.secondary)

          if let isVerified = authService.currentUser?.isEmailVerified, !isVerified {
            Text("Unverified")
              .font(.caption)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(.orange.opacity(0.2))
              .foregroundStyle(.orange)
              .clipShape(Capsule())
          }
        }
      }

      if let providerData = authService.currentUser?.providerData, !providerData.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Text("Linked Providers:")
            .font(.caption)
            .foregroundStyle(.secondary)

          ForEach(providerData, id: \.providerID) { provider in
            Label(providerIDDisplayName(provider.providerID), systemImage: providerIcon(provider.providerID))
              .font(.caption)
          }
        }
        .padding(.top, 4)
      }
    }
    .padding(.vertical, 8)
  }

  private var unauthenticatedView: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "person.crop.circle.badge.exclamationmark")
          .foregroundStyle(.red)
        Text("Not Signed In")
          .font(.headline)
      }

      Text("Sign in to access your account across devices.")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Button {
        showAuthenticationScreen = true
      } label: {
        Text("Sign In")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .padding(.top, 8)
    }
    .padding(.vertical, 8)
  }

  @ViewBuilder
  private var authenticationActionsSection: some View {
    if authService.isAuthenticated || authService.isGuestAccount {
      Section {
        Button(role: .destructive) {
          do {
            try authService.signOut()
          } catch {
            print("Sign out failed: \(error.localizedDescription)")
          }
        } label: {
          Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
        }
      }
    }
  }

  @ViewBuilder
  private var accountManagementSection: some View {
    if authService.isAuthenticated {
      Section {
        Button(role: .destructive) {
          showDeleteConfirmation = true
        } label: {
          Label("Delete Account", systemImage: "trash")
        }
      } footer: {
        Text("This will permanently delete your account and all associated data.")
      }
    }
  }
}

extension AccountView {
  private func providerIDDisplayName(_ providerID: String) -> String {
    switch providerID {
    case "password":
      return "Email"
    case "apple.com":
      return "Apple"
    case "google.com":
      return "Google"
    default:
      return providerID
    }
  }

  private func providerIcon(_ providerID: String) -> String {
    switch providerID {
    case "password":
      return "envelope"
    case "apple.com":
      return "apple.logo"
    case "google.com":
      return "globe"
    default:
      return "person.circle"
    }
  }
}

#Preview {
  NavigationStack {
    AccountView()
  }
  .environment(AuthenticationService.shared)
}