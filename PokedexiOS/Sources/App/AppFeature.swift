import SwiftUI
import ComposableArchitecture

struct AppFeature: Reducer {
  struct State: Equatable {
    var count = 0
    var imageURL = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png")

    var list = PokedexListFeature.State()
  }

  enum Action: Equatable {
    case incrementButtonTapped
    case list(PokedexListFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.list, action: /Action.list) {
      PokedexListFeature()
    }

    Reduce { state, action in
      switch action {
      case .incrementButtonTapped:
        state.count += 1
        return .none
      case .list:
        return .none
      }
    }
  }
}
