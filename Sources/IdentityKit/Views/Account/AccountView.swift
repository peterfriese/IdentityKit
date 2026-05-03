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

  private var userEmail: String? {
    authenticationService.currentUser?.email
  }

  private var isEmailVerified: Bool {
    authenticationService.currentUser?.isEmailVerified ?? false
  }

  private var providerNames: [String] {
    guard let providerData = authenticationService.currentUser?.providerData else {
      return []
    }
    return providerData.map { AuthProviderMapper.displayName(for: $0.providerID) }
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
        accountStatusSection
        if isAuthenticated {
          accountDetailsSection
          actionsSection
        } else {
          guestSection
        }
      }
      .navigationTitle("Account")
      .platform.navigationBarTitleDisplayMode(.inline)
      .platform.doneButton { dismiss() }
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
  private var accountStatusSection: some View {
    Section {
      HStack(spacing: 16) {
        Image(systemName: isAuthenticated ? "person.fill.checkmark" : "person.fill.questionmark")
          .font(.system(size: 40))
          .foregroundStyle(isAuthenticated ? .green : .orange)

        VStack(alignment: .leading, spacing: 4) {
          Text(isAuthenticated ? "Full Account" : "Guest Account")
            .font(.headline)

          if isGuest {
            Text("Data is stored on this device only")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .padding(.vertical, 8)
    }
  }

  @ViewBuilder
  private var guestSection: some View {
    Section {
      VStack(alignment: .leading, spacing: 12) {
        Label("Your data is only stored on this device", systemImage: "exclamationmark.triangle.fill")
          .font(.subheadline)
          .foregroundStyle(.orange)

        Text("Upgrade to a full account to:")
          .font(.subheadline)
          .fontWeight(.medium)

        VStack(alignment: .leading, spacing: 8) {
          Label("Sync data across devices", systemImage: "iphone.and.arrow.forward")
          Label("Recover your account with email", systemImage: "envelope.fill")
          Label("Access your account from any device", systemImage: "globe")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      .padding(.vertical, 8)

      Button {
        Task { await handleUpgrade() }
      } label: {
        Text("Upgrade to Full Account")
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
      }
      .buttonStyle(.borderedProminent)
    } header: {
      Text("Benefits")
    }
  }

  @ViewBuilder
  private var accountDetailsSection: some View {
    Section("Account Details") {
      if let email = userEmail {
        HStack {
          Text("Email")
            .foregroundStyle(.secondary)
          Spacer()
          Text(email)
          if isEmailVerified {
            Image(systemName: "checkmark.seal.fill")
              .foregroundStyle(.green)
              .symbolRenderingMode(.hierarchical)
          }
        }
      }

      if !providerNames.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Sign-in methods")
            .foregroundStyle(.secondary)

          FlowLayout(spacing: 8) {
            ForEach(providerNames, id: \.self) { provider in
              providerPill(provider)
            }
          }
        }
        .padding(.vertical, 4)
      }
    }
  }

  @ViewBuilder
  private func providerPill(_ provider: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: iconForProvider(provider))
        .font(.caption)
      Text(provider)
        .font(.caption)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .platform.secondaryBackground()
    .clipShape(Capsule())
  }

  private func iconForProvider(_ provider: String) -> String {
    AuthProviderMapper.iconName(for: provider)
  }

  @ViewBuilder
  private var actionsSection: some View {
    Section {
      Button(role: .destructive) {
        Task { await handleSignOut() }
      } label: {
        HStack {
          Text("Sign Out")
          Spacer()
          if isSigningOut {
            ProgressView()
          }
        }
      }
      .disabled(isSigningOut)

      Button(role: .destructive) {
        presentingDeleteConfirmation = true
      } label: {
        Text("Delete Account")
      }
    }
  }
}

private enum AuthProviderMapper {
  static func displayName(for providerID: String) -> String {
    switch providerID {
    case "email":
      return "Email"
    case "google.com":
      return "Google"
    case "apple.com":
      return "Apple"
    default:
      return providerID
    }
  }

  static func iconName(for providerID: String) -> String {
    switch providerID {
    case "email":
      return "envelope.fill"
    case "google.com":
      return "g.circle.fill"
    case "apple.com":
      return "apple.logo"
    default:
      return "person.fill"
    }
  }
}

struct FlowLayout: Layout {
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = arrangeSubviews(proposal: proposal, subviews: subviews)
    return result.size
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let result = arrangeSubviews(proposal: proposal, subviews: subviews)
    for (index, frame) in result.frames.enumerated() {
      subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
    }
  }

  private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
    let maxWidth = proposal.width ?? .infinity
    var frames: [CGRect] = []
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var lineHeight: CGFloat = 0
    var maxLineWidth: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)

      if currentX + size.width > maxWidth && currentX > 0 {
        currentX = 0
        currentY += lineHeight + spacing
        lineHeight = 0
      }

      frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
      lineHeight = max(lineHeight, size.height)
      currentX += size.width + spacing
      maxLineWidth = max(maxLineWidth, currentX)
    }

    let totalHeight = currentY + lineHeight
    let finalWidth = proposal.width ?? (maxLineWidth > 0 ? maxLineWidth - spacing : 0)
    return (CGSize(width: finalWidth, height: totalHeight), frames)
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