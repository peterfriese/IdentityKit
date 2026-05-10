//
// StorageService.swift
// IdentityKit
//
// Created by Peter Friese on 09.05.26
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
import FirebaseStorage
import os.log
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
@Observable
final public class StorageService {
  public static let shared = StorageService()

  private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "StorageService")
  private nonisolated(unsafe) let storage = Storage.storage()
  private let maxDimension: CGFloat = 512
  private let compressionQuality: CGFloat = 0.8

  private var isStorageAvailable: Bool? = nil

  private init() {
    validateStorageConfiguration()
  }

  deinit { }

  private func validateStorageConfiguration() {
    Task { [weak self, logger] in
      guard self != nil else { return }
      self?.storage.reference().getMetadata { [logger, weak self] _, error in
        Task { @MainActor [logger, weak self] in
          if let error {
            logger.error("Firebase Storage is not configured. Please enable it in Firebase Console → Storage → Get started.")
            self?.isStorageAvailable = false
          } else {
            self?.isStorageAvailable = true
          }
        }
      }
    }
  }

  public func uploadAvatar(imageData: Data, for userId: String) async throws -> URL {
    if isStorageAvailable == false {
      throw AuthenticationError.storageNotEnabled
    }

    if isStorageAvailable == nil {
      do {
        try await Task.sleep(nanoseconds: 500_000_000)
      } catch {
        throw AuthenticationError.storageNotEnabled
      }
      if isStorageAvailable == false {
        throw AuthenticationError.storageNotEnabled
      }
    }

    let resizedData = try resizeImage(imageData, maxDimension: maxDimension)

    return try await withCheckedThrowingContinuation { continuation in
      let avatarRef = storage.reference().child("avatars/\(userId)/profile.jpg")
      let metadata = StorageMetadata()
      metadata.contentType = "image/jpeg"

      avatarRef.putData(resizedData, metadata: metadata) { [logger, weak self] _, error in
        if let error = error as NSError? {
          if error.code == -13010 {
            Task { @MainActor [weak self] in
              self?.isStorageAvailable = false
            }
            logger.error("Firebase Storage bucket not found. Please enable Cloud Storage in Firebase Console → Storage → Get started.")
            continuation.resume(throwing: AuthenticationError.storageNotEnabled)
          } else if error.code == -13020 {
            logger.error("Firebase Storage unauthorized. Please check your Security Rules in Firebase Console → Storage → Rules.")
            continuation.resume(throwing: AuthenticationError.uploadFailed(underlying: error))
          } else {
            logger.error("Avatar upload failed: \(error.localizedDescription)")
            continuation.resume(throwing: AuthenticationError.uploadFailed(underlying: error))
          }
        } else {
          avatarRef.downloadURL { [logger] url, error in
            if let error {
              logger.error("Failed to get download URL: \(error.localizedDescription)")
              continuation.resume(throwing: AuthenticationError.uploadFailed(underlying: error))
            } else if let url {
              logger.info("Avatar uploaded successfully for user \(userId)")
              continuation.resume(returning: url)
            } else {
              continuation.resume(throwing: AuthenticationError.uploadFailed(underlying: NSError(domain: "StorageService", code: -3)))
            }
          }
        }
      }
    }
  }

  public func deleteAvatar(for userId: String) async throws {
    guard isStorageAvailable != false else {
      throw AuthenticationError.storageNotEnabled
    }

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      let avatarRef = storage.reference().child("avatars/\(userId)/profile.jpg")
      avatarRef.delete { [logger] error in
        if let error {
          logger.error("Failed to delete avatar: \(error.localizedDescription)")
          continuation.resume(throwing: AuthenticationError.storageError(underlying: error))
        } else {
          logger.info("Avatar deleted successfully for user \(userId)")
          continuation.resume()
        }
      }
    }
  }

  private func resizeImage(_ data: Data, maxDimension: CGFloat) throws -> Data {
    #if canImport(UIKit)
    guard let image = UIImage(data: data) else {
      throw AuthenticationError.storageError(underlying: NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not load image data"]))
    }

    let size = image.size
    if size.width <= maxDimension && size.height <= maxDimension {
      return data
    }

    let scaleFactor = min(maxDimension / size.width, maxDimension / size.height)
    let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    guard let resized = resizedImage, let jpegData = resized.jpegData(compressionQuality: compressionQuality) else {
      throw AuthenticationError.storageError(underlying: NSError(domain: "StorageService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not resize image"]))
    }

    return jpegData
    #elseif canImport(AppKit)
    guard let image = NSImage(data: data) else {
      throw AuthenticationError.storageError(underlying: NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not load image data"]))
    }

    let size = image.size
    if size.width <= maxDimension && size.height <= maxDimension {
      return data
    }

    let scaleFactor = min(maxDimension / size.width, maxDimension / size.height)
    let newSize = NSSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

    let resizedImage = NSImage(size: newSize)
    resizedImage.lockFocus()
    image.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
    resizedImage.unlockFocus()

    guard let tiffData = resizedImage.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality]) else {
      throw AuthenticationError.storageError(underlying: NSError(domain: "StorageService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not resize image"]))
    }

    return jpegData
    #else
    return data
    #endif
  }
}
