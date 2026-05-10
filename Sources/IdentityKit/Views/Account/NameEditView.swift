//
//  NameEditView.swift
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

struct NameEditView: View {
  @Environment(AuthenticationService.self) private var authenticationService
  @Environment(\.dismiss) private var dismiss

  private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "NameEditView")

  @State private var firstName: String = ""
  @State private var lastName: String = ""
  @State private var isSaving: Bool = false
  @State private var errorMessage: String?

  private var canSave: Bool {
    !firstName.isEmpty || !lastName.isEmpty
  }

  var body: some View {
    List {
      Section {
        TextField("First Name", text: $firstName)
        TextField("Last Name", text: $lastName)
      } header: {
        Text("Name")
      }

      if let errorMessage {
        Section {
          Text(errorMessage)
            .foregroundStyle(.red)
        }
      }
    }
    .platform.listStyle(.insetGrouped)
    .navigationTitle("Edit Name")
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
          Task {
            await saveName()
          }
        } label: {
          Label("Save", systemImage: "checkmark")
        }
        .disabled(!canSave)
      }
    }
    .onAppear {
      loadCurrentName()
    }
  }

  private func loadCurrentName() {
    guard let displayName = authenticationService.currentUser?.displayName else { return }
    let components = displayName.split(separator: " ", maxSplits: 1)
    if components.count >= 2 {
      firstName = String(components[0])
      lastName = String(components[1])
    } else if components.count == 1 {
      firstName = String(components[0])
    }
  }

  private func saveName() async {
    isSaving = true
    errorMessage = nil

    do {
      guard let user = Auth.auth().currentUser else {
        errorMessage = "User not authenticated"
        isSaving = false
        return
      }

      let fullName = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
      let changeRequest = user.createProfileChangeRequest()
      changeRequest.displayName = fullName.isEmpty ? nil : fullName
      try await changeRequest.commitChanges()

      dismiss()
    } catch {
      logger.error("Failed to update name: \(error.localizedDescription)")
      errorMessage = "Failed to update name. Please try again."
    }

    isSaving = false
  }
}

#Preview {
  NavigationStack {
    NameEditView()
      .environment(AuthenticationService.shared)
  }
}