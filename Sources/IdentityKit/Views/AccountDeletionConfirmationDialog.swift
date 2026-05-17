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

/// The result of an account deletion confirmation dialog.
public enum AccountDeletionConfirmationResult {
  case cancel
  case confirm
}

/// A dialog view for confirming account deletion.
///
/// This view presents a confirmation dialog to the user before they delete their account,
/// ensuring they understand the permanent consequences of account deletion.
public struct AccountDeletionConfirmationDialog: View {
  @Environment(\.dismiss) var dismiss

  private var action: @MainActor () -> Void

  @State private var result: AccountDeletionConfirmationResult?

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
          result = .confirm
          dismiss()
        }) {
          Text("Delete account permanently")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(8)
        }
        .buttonStyle(.borderedProminent)

        Button(role: .cancel, action: {
          result = .cancel
          dismiss()
        }) {
          Text("Not now")
        }
      }
    }
    .padding()
    .onDisappear() {
      Task {
        if result == .confirm {
          action()
        }
      }
    }
  }
}

#Preview {
  AccountDeletionConfirmationDialog {
  }
}
