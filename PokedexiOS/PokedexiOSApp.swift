//
//  PokedexiOSApp.swift
//  PokedexiOS
//
//  Created by Alexander Chen on 2025/9/8.
//

import SwiftUI
import ComposableArchitecture

@main
struct PokedexiOSApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
              store: Store(initialState: AppFeature.State()) {
                AppFeature()
              }
            )
        }
    }
}
