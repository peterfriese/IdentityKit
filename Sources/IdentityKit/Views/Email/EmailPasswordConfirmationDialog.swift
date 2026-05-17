//
//  EmailConfirmationDialog.swift
//  IdentityKit
//
//  Created by Peter Friese on 07.03.25
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

import Foundation
#if canImport(UIKit)
import UIKit
import SwiftUI
import FirebaseAuth
import os.log

/// Errors that can occur during email/password confirmation.
public enum EmailPasswordConfirmationError: Error, LocalizedError {
  case rootViewControllerNotFound

  public var errorDescription: String? {
    switch self {
    case .rootViewControllerNotFound:
      return "Could not find root view controller"
    }
  }
}

private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "EmailPasswordConfirmation")

/// Prompts the user to confirm their password using the system dialog.
///
/// This function presents a native password confirmation dialog to verify
/// the user's identity before performing sensitive operations.
///
/// - Parameter email: The email address associated with the account.
/// - Returns: The confirmed password string.
/// - Throws: ``EmailPasswordConfirmationError`` if confirmation fails.
public func confirmPassword(for email: String) async throws -> String {
  return try await EmailPasswordConfirmationDialog().confirmPassword(for: email)
}

/// A dialog for confirming user password using ASPasswordCredential.
///
/// This class presents a native system dialog to verify the user's identity
/// before performing sensitive operations like email updates or account deletion.
@MainActor
public class EmailPasswordConfirmationDialog: NSObject {
  private var continuation: CheckedContinuation<String, Error>?

  private func findTopmostViewController(from viewController: UIViewController) -> UIViewController {
    if let presentedViewController = viewController.presentedViewController {
      return findTopmostViewController(from: presentedViewController)
    }

    if let navigationController = viewController as? UINavigationController {
      return navigationController.visibleViewController.map(findTopmostViewController) ?? navigationController
    }

    if let tabBarController = viewController as? UITabBarController {
      return tabBarController.selectedViewController.map(findTopmostViewController) ?? tabBarController
    }

    if let splitViewController = viewController as? UISplitViewController {
      if let detailViewController = splitViewController.viewController(for: .secondary) {
        return findTopmostViewController(from: detailViewController)
      } else if let primaryViewController = splitViewController.viewController(for: .primary) {
        return findTopmostViewController(from: primaryViewController)
      }
    }

    return viewController
  }

  public func confirmPassword(for email: String) async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation

      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController else {
        logger.error("Failed to find root view controller for email confirmation dialog")
        self.continuation?.resume(throwing: EmailPasswordConfirmationError.rootViewControllerNotFound)
        self.continuation = nil
        return
      }

      let topmostViewController = self.findTopmostViewController(from: rootViewController)

      logger.debug("Showing password confirmation dialog for email: \(email)")
      let loginView = EmailPasswordConfirmationView(email: email) {
        logger.debug("Password confirmation completed successfully")
        continuation.resume(returning: $0)
      }
        .padding()

      let hostingController = UIHostingController(rootView: loginView)
      hostingController.modalPresentationStyle = .pageSheet
      hostingController.sheetPresentationController?.detents = [.medium()]
      hostingController.sheetPresentationController?.prefersGrabberVisible = true

      topmostViewController.present(hostingController, animated: true)
    }
  }
}
#endif

#if canImport(UIKit)
#Preview {
  Button("Login") {
    Task {
      do {
        let password = try await EmailPasswordConfirmationDialog().confirmPassword(for: "test@test.com")
        print(password)
      } catch {
        print("Error: \(error.localizedDescription)")
      }
    }
  }
}
#endif