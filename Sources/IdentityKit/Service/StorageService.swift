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

/// A service for managing avatar image storage using Firebase Storage.
///
/// This service handles uploading, resizing, and deleting user avatar images.
/// Images are resized to a maximum dimension of 512px and compressed to 80% JPEG quality.
///
/// ## Topics
/// ### Initializers
/// - ``init()``
/// - ``shared``
///
/// ### Methods
/// - ``uploadAvatar(imageData:for:)``
/// - ``deleteAvatar(for:)``
@MainActor
@Observable
final public class StorageService {
  public static let shared = StorageService()

  private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "StorageService")
  private nonisolated(unsafe) let storage = Storage.storage()
  private let maxDimension: CGFloat = 512
  private let compressionQuality: CGFloat = 0.8

  private init() {}

  public func uploadAvatar(imageData: Data, for userId: String) async throws -> URL {
    let resizedData = try resizeImage(imageData, maxDimension: maxDimension)

    let avatarRef = storage.reference().child("avatars/\(userId)/profile.jpg")
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"

    do {
      _ = try await avatarRef.putData(resizedData, metadata: metadata)
      let url = try await downloadURL(from: avatarRef)
      logger.info("Avatar uploaded successfully for user \(userId)")
      return url
    } catch let error as NSError {
      if error.code == -13010 {
        logger.error("Firebase Storage bucket not found. Please enable Cloud Storage in Firebase Console → Storage → Get started.")
        throw AuthenticationError.storageNotEnabled
      } else if error.code == -13020 {
        logger.error("Firebase Storage unauthorized. Please check your Security Rules in Firebase Console → Storage → Rules.")
        throw AuthenticationError.uploadFailed(underlying: error)
      } else {
        logger.error("Avatar upload failed: \(error.localizedDescription)")
        throw AuthenticationError.uploadFailed(underlying: error)
      }
    } catch {
      logger.error("Avatar upload failed: \(error.localizedDescription)")
      throw AuthenticationError.uploadFailed(underlying: error)
    }
  }

  private func downloadURL(from ref: StorageReference) async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
      ref.downloadURL { url, error in
        if let error {
          continuation.resume(throwing: error)
        } else if let url {
          continuation.resume(returning: url)
        } else {
          continuation.resume(throwing: AuthenticationError.uploadFailed(underlying: NSError(domain: "StorageService", code: -3)))
        }
      }
    }
  }

  public func deleteAvatar(for userId: String) async throws {
    let avatarRef = storage.reference().child("avatars/\(userId)/profile.jpg")
    try await deleteStorageRef(avatarRef)
    logger.info("Avatar deleted successfully for user \(userId)")
  }

  private func deleteStorageRef(_ ref: StorageReference) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      ref.delete { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
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

    let renderer = UIGraphicsImageRenderer(size: newSize)
    let jpegData = renderer.jpegData(withCompressionQuality: compressionQuality, actions: { _ in
      image.draw(in: CGRect(origin: .zero, size: newSize))
    })

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