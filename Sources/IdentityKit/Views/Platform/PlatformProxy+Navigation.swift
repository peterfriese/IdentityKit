//
//  PlatformProxy+Navigation.swift
//  IdentityKit
//
//  Created by Peter Friese on 03.05.26
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

extension PlatformProxy where Content: View {
    @ViewBuilder
    public func navigationBarTitleDisplayMode(_ mode: PlatformTitleDisplayMode) -> some View {
        #if os(iOS)
        content.navigationBarTitleDisplayMode(mode.swiftUI)
        #else
        content
        #endif
    }
}

#if os(iOS)
extension PlatformTitleDisplayMode {
    var swiftUI: NavigationBarItem.TitleDisplayMode {
        switch self {
        case .automatic: return .automatic
        case .inline: return .inline
        case .large: return .large
        }
    }
}
#endif