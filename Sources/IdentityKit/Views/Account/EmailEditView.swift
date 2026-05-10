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
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

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

  private var canProceed: Bool {
    !newEmail.isEmpty && newEmail == confirmEmail && newEmail.contains("@")
  }

  var body: some View {
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
    .platform.listStyle(.insetGrouped)
    .navigationTitle("Change Email")
    .platform.navigationBarTitleDisplayMode(.inline)
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
    .sheet(isPresented: $showingReauth) {
      ReauthenticationView { password in
        Task {
          await updateEmail(withPassword: password)
        }
      }
    }
    .interactiveDismissDisabled(isSaving)
  }

  private func updateEmail(withPassword password: String) async {
    isSaving = true
    errorMessage = nil

    do {
      guard let user = Auth.auth().currentUser else {
        errorMessage = "User not authenticated"
        isSaving = false
        return
      }

      let credential = EmailAuthProvider.credential(withEmail: user.email ?? newEmail, password: password)
      try await user.reauthenticate(with: credential)
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