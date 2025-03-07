//
// EmailConfirmationDialog.swift
// IdentityKit
//
// Created by Peter Friese on 07.03.25.
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

import Foundation
import UIKit
import SwiftUI
import FirebaseAuth

public func confirmPassword(for email: String) async throws -> String {
  return try await EmailPasswordConfirmationDialog().confirmPassword(for: email)
}

@MainActor
public class EmailPasswordConfirmationDialog: NSObject {
  private var continuation: CheckedContinuation<String, Error>?

  public func confirmPassword(for email: String) async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation

      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController else {
        self.continuation?.resume(throwing: NSError(domain: "", code: -1,
                                                    userInfo: [NSLocalizedDescriptionKey: "Could not find root view controller"]))
        self.continuation = nil
        return
      }

      let loginView = EmailPasswordConfirmationView(email: email) {
        continuation.resume(returning: $0)
      }
        .padding()

      let hostingController = UIHostingController(rootView: loginView)
      hostingController.modalPresentationStyle = .pageSheet
      hostingController.sheetPresentationController?.detents = [.medium()]
      hostingController.sheetPresentationController?.prefersGrabberVisible = true

      rootViewController.present(hostingController, animated: true)
    }
  }
}

#Preview {
  Button("Login") {
    Task {
      let password = try await EmailPasswordConfirmationDialog().confirmPassword(for: "test@test.com")
      print(password)
    }
  }
}
