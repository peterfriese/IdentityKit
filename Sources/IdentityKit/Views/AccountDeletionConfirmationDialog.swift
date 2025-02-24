//
// AccountDeletionConfirmationDialog.swift
// IdentityKit
//
// Created by Peter Friese on 19.02.25.
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

public struct AccountDeletionConfirmationDialog: View {
  @Environment(\.dismiss) var dismiss

  private var action: @MainActor () -> Void

  public init(action: @escaping @MainActor () -> Void) {
    self.action = action
  }

  public var body: some View {
    VStack {
      Spacer()
      Image(systemName: "person.fill.xmark")
        .symbolRenderingMode(.palette)
        .font(.system(size: 72))
        .foregroundStyle(.red, .secondary)
      VStack(spacing: 10) {
        Text("Delete Account")
          .font(.largeTitle.bold())
        Text("This is a permanent action and cannot be undone.")
          .font(.headline)
          .foregroundStyle(.secondary)
        Text("Note: You will asked to authorize this security-sensitive operation.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .multilineTextAlignment(.center)
      Spacer()
      VStack(spacing: 16) {
        Button(role: .destructive, action: {
          action()
          dismiss()
        }) {
          Text("Delete account permanently")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(8)
        }
        .buttonStyle(.borderedProminent)

        Button(role: .cancel, action: { dismiss() }) {
          Text("Not now")
        }
      }
    }
    .padding()
  }
}

#Preview {
  AccountDeletionConfirmationDialog {
  }
}
