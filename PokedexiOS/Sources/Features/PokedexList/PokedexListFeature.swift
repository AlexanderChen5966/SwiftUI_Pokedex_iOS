import Foundation
import ComposableArchitecture

public struct PokedexListFeature: Reducer {
  public struct State: Equatable {
    // Data
    public var all: [Pokemon] = []
    public var filtered: [Pokemon] = []

    // UI
    @BindingState public var searchText: String = ""
    public var isLoading: Bool = false
    public var imageStyle: ImageStyle = .official
    public var isShiny: Bool = false

    public init() {}
  }

  public enum ImageStyle: String, CaseIterable, Equatable {
    case sprite
    case official
  }

    public enum Action: BindableAction, Equatable {
        public static func == (lhs: PokedexListFeature.Action, rhs: PokedexListFeature.Action) -> Bool {
            return true
        }
        
    case onAppear
    case refreshPulled
    case loadResponse(Result<[Pokemon], Error>)

    case setImageStyle(ImageStyle)
    case toggleShiny(Bool)

    case binding(BindingAction<State>)
  }

  private let api = APIClientLive()

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .onAppear, .refreshPulled:
        state.isLoading = true
        return .run { send in
          do {
            let list = try await api.fetchPokemon()
            await send(.loadResponse(.success(list)))
          } catch {
            await send(.loadResponse(.failure(error)))
          }
        }

      case let .loadResponse(result):
        state.isLoading = false
        switch result {
        case let .success(list):
          state.all = list
          filter(state: &state)
        case .failure:
          state.all = Self.samples
          filter(state: &state)
        }
        return .none

      case let .setImageStyle(style):
        state.imageStyle = style
        return .none

      case let .toggleShiny(isOn):
        state.isShiny = isOn
        return .none

      case .binding(_):
        filter(state: &state)
        return .none
      }
    }
  }

  private func filter(state: inout State) {
    let q = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if q.isEmpty {
      state.filtered = state.all
    } else {
      state.filtered = state.all.filter { p in
        if p.name.lowercased().contains(q) { return true }
        if p.types.joined(separator: ", ").lowercased().contains(q) { return true }
        if let category = p.category?.lowercased(), category.contains(q) { return true }
        return String(p.id).contains(q)
      }
    }
  }
}

extension PokedexListFeature {
  // Lightweight fallback data to enable UI during development.
  static let samples: [Pokemon] = [
    Pokemon(id: 1, name: "Bulbasaur", image: nil, height: 0.7, weight: 6.9, category: "Seed", gender: nil, abilities: ["Overgrow"], weakness: ["Fire", "Flying", "Ice", "Psychic"], types: ["Grass", "Poison"]),
    Pokemon(id: 4, name: "Charmander", image: nil, height: 0.6, weight: 8.5, category: "Lizard", gender: nil, abilities: ["Blaze"], weakness: ["Water", "Ground", "Rock"], types: ["Fire"]),
    Pokemon(id: 7, name: "Squirtle", image: nil, height: 0.5, weight: 9.0, category: "Tiny Turtle", gender: nil, abilities: ["Torrent"], weakness: ["Electric", "Grass"], types: ["Water"])
  ]
}
