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

struct EmailEditView: View {
  @Environment(AccountService.self) private var accountService
  @Environment(AuthenticationService.self) private var authenticationService
  @Environment(\.dismiss) private var dismiss

  @State private var email: String = ""
  @State private var showingReauthentication = false
  @State private var errorMessage: String?
  @State private var error: Error?

  private var currentEmail: String? {
    authenticationService.userEmail
  }

  private var canSave: Bool {
    !email.isEmpty && email != currentEmail
  }

  var body: some View {
    List {
      Section {
        emailTextField
      } header: {
        Text("Email")
      }

      if let errorMessage {
        Section {
          Text(errorMessage)
            .foregroundStyle(.red)
        }
      }
    }
    .platform.listStyle(.insetGrouped)
    .navigationTitle("Edit Email")
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
        Button {
          showingReauthentication = true
        } label: {
          Label("Save", systemImage: "checkmark")
        }
        .disabled(!canSave)
      }
    }
    .onAppear {
      loadCurrentEmail()
    }
    .sheet(isPresented: $showingReauthentication) {
      NavigationStack {
        AuthenticationScreen(flow: .reauthentication) { result in
          showingReauthentication = false
          switch result {
          case .success:
            Task {
              await updateEmail()
            }
          case .cancelled:
            break
          case .failure(let error):
            errorMessage = error.localizedDescription
          }
        }
      }
    }
  }

  private var emailTextField: some View {
    TextField("Email", text: $email)
      .textContentType(.emailAddress)
  }

  private func loadCurrentEmail() {
    email = currentEmail ?? ""
  }

  private func updateEmail() async {
    do {
      try await accountService.updateEmail(email)
      dismiss()
    }
    catch AuthenticationError.reauthenticationRequired {
      errorMessage = AuthenticationError.reauthenticationRequired.errorDescription
      showingReauthentication = true
    }
    catch {
      errorMessage = "Failed to update email. Please try again."
    }
  }
}

#Preview {
  NavigationStack {
    EmailEditView()
      .environment(AccountService.shared)
      .environment(AuthenticationService.shared)
  }
}