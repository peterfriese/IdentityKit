//
// View+AuthenticationProviders.swift
// IdentityKit
//
// Created by Peter Friese on 17.03.25.
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

public enum AuthenticationProvider {
  case email
  case google
  case apple
}

public extension EnvironmentValues {
  @Entry
  public var authenticationProviders: [AuthenticationProvider] = []
}

public extension View {
  public func authenticationProviders(_ providers: [AuthenticationProvider]) -> some View {
    environment(\.authenticationProviders, providers)
  }
}
