import Foundation
import ComposableArchitecture

public struct PokemonDetailFeature: Reducer {
  public struct State: Equatable {
    public var pokemon: Pokemon

    public init(pokemon: Pokemon) {
      self.pokemon = pokemon
    }
  }

  public enum Action: Equatable {
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      }
    }
  }
}

