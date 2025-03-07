//
// EmailPasswordAuthenticationView.swift
// IdentityKit
//
// Created by Peter Friese on 28.01.25.
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

@MainActor
struct EmailPasswordConfirmationView {
  // MARK: - Dependencies
  @Environment(\.dismiss) private var dismiss

  // MARK: - Private properties
  private var onConfirm: (String) -> Void
  private var email = ""
  @State private var password = ""

  private var isValid: Bool {
    !password.isEmpty
  }

  init(email: String, onConfirm: @escaping (String) -> Void) {
    self.email = email
    self.onConfirm = onConfirm
  }

  private func confirmPassword() async {
    dismiss()
    onConfirm(password)
  }
}

extension EmailPasswordConfirmationView: View {
  var body: some View {
    VStack {
      LabeledContent {
        Text(email)
          .frame(maxWidth: .infinity, alignment: .leading)
      } label: {
        Image(systemName: "at")
      }
      .padding(.vertical, 6)
      .background(Divider(), alignment: .bottom)
      .padding(.bottom, 4)

      LabeledContent {
        SecureField("Password", text: $password)
        //          .focused($focus, equals: .password)
          .submitLabel(.go)
          .onSubmit {
            Task { await confirmPassword() }
          }
      } label: {
        Image(systemName: "lock")
      }
      .padding(.vertical, 6)
      .background(Divider(), alignment: .bottom)
      .padding(.bottom, 8)

      Button(action: {
        Task { await confirmPassword() }
      }) {
        Text("Confirm password")
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity)
      }
      .disabled(!isValid)
      .padding([.top, .bottom], 8)
      .frame(maxWidth: .infinity)
      .buttonStyle(.borderedProminent)
    }
  }
}

#Preview {
  EmailPasswordConfirmationView(email: "test@test.com") {
    print($0)
  }
}
