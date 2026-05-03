//
// AuthenticationService+Google.swift
// IdentityKit
//
// Created by Peter Friese on 03.05.26
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

import FirebaseAuth
import FirebaseCore
import GoogleSignIn

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension AuthenticationService {
  @MainActor
  @discardableResult
  func signInWithGoogle() async throws -> Bool {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
      throw AuthenticationError.googleSignInFailed
    }

    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

    #if os(iOS)
    guard let presentingViewController = getPresentingViewController() else {
      throw AuthenticationError.googleSignInFailed
    }

    do {
      let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

      guard let idToken = result.user.idToken?.tokenString else {
        throw AuthenticationError.missingGoogleIDToken
      }

      let accessToken = result.user.accessToken.tokenString

      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

      return try await linkOrSignIn(with: credential)
    } catch let error as GIDSignInError {
      if error.code == .canceled {
        throw AuthenticationError.googleSignInCancelled
      }
      throw AuthenticationError.googleSignInFailed
    }
    #elseif os(macOS)
    guard let window = NSApplication.shared.keyWindow else {
      throw AuthenticationError.googleSignInFailed
    }

    do {
      let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)

      guard let idToken = result.user.idToken?.tokenString else {
        throw AuthenticationError.missingGoogleIDToken
      }

      let accessToken = result.user.accessToken.tokenString

      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

      return try await linkOrSignIn(with: credential)
    } catch let error as GIDSignInError {
      if error.code == .canceled {
        throw AuthenticationError.googleSignInCancelled
      }
      throw AuthenticationError.googleSignInFailed
    }
    #endif
  }

  private func linkOrSignIn(with credential: AuthCredential) async throws -> Bool {
    do {
      try await link(with: credential)
      return true
    } catch let error as NSError where error.credentialAlreadyInUse {
      if let updatedCredential = error.userInfo[AuthErrors.userInfoUpdatedCredentialKey] as? AuthCredential {
        try await signIn(with: updatedCredential)
        return true
      } else {
        throw AuthenticationError.credentialAlreadyInUse(underlying: error)
      }
    } catch {
      throw AuthenticationError.signInFailed(underlying: error)
    }
  }

  #if os(iOS)
  private func getPresentingViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first,
          let rootViewController = window.rootViewController else {
      return nil
    }

    var topController = rootViewController
    while let presentedController = topController.presentedViewController {
      topController = presentedController
    }
    return topController
  }
  #endif
}