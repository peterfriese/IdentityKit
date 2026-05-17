//
//  PasswordEditView.swift
//  IdentityKit
//
//  Created by Peter Friese on 15.05.26
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
//

import SwiftUI
import os.log

enum PasswordEditMode {
  case setPassword
  case changePassword
}

@MainActor
struct PasswordEditView: View {
  @Environment(AuthenticationService.self) private var authenticationService
  @Environment(\.dismiss) private var dismiss

  private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "PasswordEditView")
  private let mode: PasswordEditMode
  private let validator = PasswordValidator()
  private let policy = PasswordPolicy.standard
  private let debounceDuration: UInt64 = 300_000_000

  @State private var currentPassword: String = ""
  @State private var newPassword: String = ""
  @State private var confirmPassword: String = ""

  @State private var showCurrentPassword: Bool = false
  @State private var showNewPassword: Bool = false
  @State private var showConfirmPassword: Bool = false

  @State private var showingReauth: Bool = false
  @State private var isSaving: Bool = false
  @State private var errorMessage: String?

  @State private var validationResult: PasswordValidationResult = PasswordValidationResult(isValid: false)
  @State private var lastValidatedPassword: String = ""

  init(mode: PasswordEditMode = .changePassword) {
    self.mode = mode
  }

  private var hasPasswordProvider: Bool {
    guard let providerData = authenticationService.currentUser?.providerData else {
      return false
    }
    return providerData.contains { $0.providerID == "password" || $0.providerID == "email" }
  }

  private var currentSignInProvider: String? {
    nil
  }

  private var passwordsMatch: Bool {
    newPassword == confirmPassword && !newPassword.isEmpty
  }

  private var canProceed: Bool {
    if mode == .changePassword {
      return !currentPassword.isEmpty && passwordsMatch && validationResult.isValid
    } else {
      return passwordsMatch && validationResult.isValid
    }
  }

  private var requirements: [PasswordRequirement] {
    PasswordValidator.requirements(for: policy)
  }

  private func description(for requirement: PasswordRequirement) -> String {
    validator.description(for: requirement)
  }

  private func validatePassword() {
    guard newPassword != lastValidatedPassword else { return }
    lastValidatedPassword = newPassword
    validationResult = validator.validate(newPassword)
  }

  var body: some View {
    Group {
      if hasPasswordProvider {
        passwordForm
      } else {
        unavailableView
      }
    }
    .platform.listStyle(.insetGrouped)
    .navigationTitle(mode == .setPassword ? "Set Password" : "Change Password")
    .platform.navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showingReauth) {
      AuthenticationScreen(flow: .reauthentication) { result in
        switch result {
        case .success:
          Task { await updatePassword() }
        case .cancelled:
          break
        case .failure(let error):
          errorMessage = error.localizedDescription
        }
      }
    }
    .interactiveDismissDisabled(isSaving)
  }

  @ViewBuilder
  private var passwordForm: some View {
    List {
      if mode == .changePassword {
        currentPasswordSection
      }

      newPasswordSection
      confirmPasswordSection

      requirementsSection

      if let errorMessage {
        Section {
          Text(errorMessage)
            .foregroundStyle(.red)
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button {
          dismiss()
        } label: {
          Label("Cancel", systemImage: "xmark")
        }
      }

      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          Task { await savePassword() }
        }
        .disabled(!canProceed || isSaving)
      }
    }
  }

  @ViewBuilder
  private var unavailableView: some View {
    VStack(spacing: 24) {
      Image(systemName: "lock.slash")
        .font(.system(size: 60))
        .foregroundStyle(.secondary)

      VStack(spacing: 8) {
        Text("Password Changes Unavailable")
          .font(.title2)
          .fontWeight(.bold)

        Text("Password changes are only available for accounts signed in with email and password. Since you're signed in with another provider, you can't change your password here. To change your password, you'll need to do so in your account settings.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      Spacer()

      Button {
        dismiss()
      } label: {
        Text("Done")
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(32)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button {
          dismiss()
        } label: {
          Label("Cancel", systemImage: "xmark")
        }
      }
    }
  }

  @ViewBuilder
  private var currentPasswordSection: some View {
    Section {
      SecureFieldWithToggle(password: $currentPassword, showPassword: $showCurrentPassword, placeholder: "Current password")
    } header: {
      Text("Current Password")
    }
  }

  @ViewBuilder
  private var newPasswordSection: some View {
    Section {
      SecureFieldWithToggle(password: $newPassword, showPassword: $showNewPassword, placeholder: "New password")
        .onChange(of: newPassword) { _, _ in
          Task {
            try? await Task.sleep(nanoseconds: debounceDuration)
            validatePassword()
          }
        }
    } header: {
      Text("New Password")
    } footer: {
      if !newPassword.isEmpty && !validationResult.isValid {
        Text("Password does not meet requirements")
          .foregroundStyle(.orange)
      }
    }
  }

  @ViewBuilder
  private var confirmPasswordSection: some View {
    Section {
      SecureFieldWithToggle(password: $confirmPassword, showPassword: $showConfirmPassword, placeholder: "Confirm new password")
    } header: {
      Text("Confirm Password")
    } footer: {
      if !confirmPassword.isEmpty && newPassword != confirmPassword {
        Text("Passwords do not match")
          .foregroundStyle(.red)
      }
    }
  }

  @ViewBuilder
  private var requirementsSection: some View {
    Section {
      ForEach(requirements, id: \.self) { requirement in
        HStack {
          Image(systemName: validationResult.missingRequirements.contains(requirement) ? "circle" : "checkmark.circle.fill")
            .foregroundStyle(validationResult.missingRequirements.contains(requirement) ? .secondary : Color.green)
          Text(description(for: requirement))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
    } header: {
      Text("Password Requirements")
    }
  }

  private func savePassword() async {
    if currentPassword.isEmpty {
      showingReauth = true
    } else {
      await updatePassword()
    }
  }

  private func updatePassword() async {
    isSaving = true
    errorMessage = nil

    do {
      try await AccountService.shared.changePassword(currentPassword: mode == .changePassword ? currentPassword : nil, newPassword: newPassword)
      dismiss()
    } catch {
      logger.error("Failed to update password: \(error.localizedDescription)")
      errorMessage = "Failed to update password. Please try again."
    }

    isSaving = false
  }
}

struct SecureFieldWithToggle: View {
  @Binding var password: String
  @Binding var showPassword: Bool
  let placeholder: String

  var body: some View {
    HStack {
      Group {
        if showPassword {
          TextField(placeholder, text: $password)
        } else {
          SecureField(placeholder, text: $password)
        }
      }
      .textContentType(.password)

      Button {
        showPassword.toggle()
      } label: {
        Image(systemName: showPassword ? "eye.slash" : "eye")
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
    }
  }
}

#Preview("Change Password") {
  NavigationStack {
    PasswordEditView(mode: .changePassword)
      .environment(AuthenticationService.shared)
  }
}

#Preview("Set Password") {
  NavigationStack {
    PasswordEditView(mode: .setPassword)
      .environment(AuthenticationService.shared)
  }
}