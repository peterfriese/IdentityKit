//
//  ReauthenticationView.swift
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

struct ReauthenticationView: View {
  @Environment(\.dismiss) private var dismiss

  private let onReauthenticate: (String) -> Void

  @State private var password: String = ""
  @State private var isAuthenticating: Bool = false
  @State private var errorMessage: String?

  private var canAuthenticate: Bool {
    !password.isEmpty
  }

  init(onReauthenticate: @escaping (String) -> Void) {
    self.onReauthenticate = onReauthenticate
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          SecureField("Password", text: $password)
            .textContentType(.password)
        } header: {
          Text("Password")
        } footer: {
          Text("Enter your password to continue")
        }

        if let errorMessage {
          Section {
            Text(errorMessage)
              .foregroundStyle(.red)
          }
        }
      }
      .platform.listStyle(.insetGrouped)
      .navigationTitle("Verify Identity")
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
            isAuthenticating = true
            onReauthenticate(password)
          } label: {
            if isAuthenticating {
              ProgressView()
            } else {
              Text("Continue")
            }
          }
          .disabled(!canAuthenticate)
        }
      }
    }
  }
}

#Preview {
  ReauthenticationView { password in
    print("Reauthenticate with: \(password)")
  }
}