import SwiftUI
import ComposableArchitecture

struct AppFeature: Reducer {
  struct State: Equatable {
    var count = 0
    var imageURL = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png")
  }

  enum Action: Equatable {
    case incrementButtonTapped
  }

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .incrementButtonTapped:
      state.count += 1
      return .none
    }
  }
}
