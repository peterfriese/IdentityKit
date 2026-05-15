//
//  EmailEditView.swift
//  IdentityKit
//
//  Created by Peter Friese on 09.05.26
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI
import os.log
import FirebaseAuth

struct EmailEditView: View {
  @Environment(AuthenticationService.self) private var authenticationService
  @Environment(\.dismiss) private var dismiss

  private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "EmailEditView")

  @State private var newEmail: String = ""
  @State private var confirmEmail: String = ""
  @State private var showingReauth: Bool = false
  @State private var isSaving: Bool = false
  @State private var errorMessage: String?

  private var hasPasswordProvider: Bool {
    guard let providerData = authenticationService.currentUser?.providerData else {
      return false
    }
    return providerData.contains { $0.providerID == "password" || $0.providerID == "email" }
  }

  private var canProceed: Bool {
    !newEmail.isEmpty && newEmail == confirmEmail && newEmail.contains("@")
  }

  var body: some View {
    Group {
      if hasPasswordProvider {
        emailForm
      } else {
        unavailableView
      }
    }
    .platform.listStyle(.insetGrouped)
    .navigationTitle("Change Email")
    .platform.navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showingReauth) {
      AuthenticationScreen(flow: .reauthentication) { result in
        switch result {
        case .success:
          Task { await updateEmail() }
        case .cancelled:
          break
        case .failure(let error):
          errorMessage = error.localizedDescription
          isSaving = false
        }
      }
    }
    .interactiveDismissDisabled(isSaving)
  }

  @ViewBuilder
  private var emailForm: some View {
    List {
      Section {
        TextField("New Email", text: $newEmail)
        TextField("Confirm Email", text: $confirmEmail)
      } header: {
        Text("Email Address")
      } footer: {
        if newEmail.isEmpty || confirmEmail.isEmpty {
          Text("Enter your new email address")
        } else if newEmail != confirmEmail {
          Text("Email addresses do not match")
        } else if !newEmail.contains("@") {
          Text("Enter a valid email address")
        }
      }

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
        Button("Next") {
          showingReauth = true
        }
        .disabled(!canProceed)
      }
    }
  }

  @ViewBuilder
  private var unavailableView: some View {
    VStack(spacing: 24) {
      Image(systemName: "envelope.badge.shuffle.halftone")
        .font(.system(size: 60))
        .foregroundStyle(.secondary)

      VStack(spacing: 8) {
        Text("Email Changes Unavailable")
          .font(.title2)
          .fontWeight(.bold)

        Text("Email changes are only available for accounts signed in with email and password. Since you're signed in with another provider, you can't change your email here. To change your email, you'll need to do so in your account settings.")
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

  private func updateEmail() async {
    isSaving = true
    errorMessage = nil

    do {
      guard let user = Auth.auth().currentUser else {
        errorMessage = "User not authenticated"
        isSaving = false
        return
      }

      try await user.updateEmail(to: newEmail)
      dismiss()
    } catch {
      logger.error("Failed to update email: \(error.localizedDescription)")
      errorMessage = "Failed to update email. Please try again."
    }

    isSaving = false
  }
}

#Preview {
  NavigationStack {
    EmailEditView()
      .environment(AuthenticationService.shared)
  }
}