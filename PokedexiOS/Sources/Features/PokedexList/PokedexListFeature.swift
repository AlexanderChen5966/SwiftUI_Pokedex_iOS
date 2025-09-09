import Foundation
import ComposableArchitecture

public struct PokedexListFeature: Reducer {
  public struct State: Equatable {
    // Data
    public var all: [Pokemon] = []
    public var filtered: [Pokemon] = []
    public var generations: [GenerationCategory] = []

    // UI
    @BindingState public var searchText: String = ""
    public var isLoading: Bool = false
    public var imageStyle: ImageStyle = .official
    public var isShiny: Bool = false

    // Filters
    public var selectedGeneration: GenerationCategory? = nil
    public var formFilters: Set<FormFilter> = []
    public var captureFilter: CaptureFilter = .all
    public var caughtSet: Set<String> = [] // {id}-{sub_id or 0}

    public init() {}
  }

  public enum ImageStyle: String, CaseIterable, Equatable {
    case sprite
    case official
  }

  public enum FormFilter: Hashable {
    case mega
    case gmax
    case otherForms
  }

  public enum CaptureFilter: Equatable, CaseIterable {
    case all
    case caught
    case uncaught
  }

    public enum Action: BindableAction, Equatable {
        public static func == (lhs: PokedexListFeature.Action, rhs: PokedexListFeature.Action) -> Bool {
            return true
        }
        
    case onAppear
    case refreshPulled
    case loadResponse(Result<[Pokemon], Error>)
    case loadGenerationsResponse(Result<[GenerationCategory], Error>)

    case setImageStyle(ImageStyle)
    case toggleShiny(Bool)

    // Filter actions
    case setCaptureFilter(CaptureFilter)
    case setSelectedGeneration(GenerationCategory?)
    case toggleFormFilter(FormFilter, Bool)

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
            async let pokemon = api.fetchPokemon()
            async let generations = api.fetchGenerations()

            let list = try await pokemon
            let gens = try await generations
            await send(.loadResponse(.success(list)))
            await send(.loadGenerationsResponse(.success(gens)))
          } catch {
            await send(.loadResponse(.failure(error)))
            await send(.loadGenerationsResponse(.failure(error)))
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

      case let .loadGenerationsResponse(result):
        switch result {
        case let .success(list):
          state.generations = list
        case .failure:
          state.generations = []
        }
        return .none

      case let .setImageStyle(style):
        state.imageStyle = style
        return .none

      case let .toggleShiny(isOn):
        state.isShiny = isOn
        return .none

      case let .setCaptureFilter(newFilter):
        state.captureFilter = newFilter
        filter(state: &state)
        return .none

      case let .setSelectedGeneration(gen):
        state.selectedGeneration = gen
        filter(state: &state)
        return .none

      case let .toggleFormFilter(kind, isOn):
        if isOn { state.formFilters.insert(kind) } else { state.formFilters.remove(kind) }
        filter(state: &state)
        return .none

      case .binding(_):
        filter(state: &state)
        return .none
      }
    }
  }

  private func filter(state: inout State) {
    // Start with all
    var list = state.all

    // Search: name, id, types, category (contains)
    let q = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if !q.isEmpty {
      list = list.filter { p in
        if p.name.lowercased().contains(q) { return true }
        if p.types.joined(separator: ", ").lowercased().contains(q) { return true }
        if let category = p.category?.lowercased(), category.contains(q) { return true }
        return String(p.id).contains(q)
      }
    }

    // Forms filter: if any selected, include items that match any selected kind.
    if !state.formFilters.isEmpty {
      list = list.filter { p in
        let kind = formKind(of: p)
        return kind.contains(where: { state.formFilters.contains($0) })
      }
    }

    // Capture filter
    switch state.captureFilter {
    case .all:
      break
    case .caught:
      list = list.filter { state.caughtSet.contains(captureKey(for: $0)) }
    case .uncaught:
      list = list.filter { !state.caughtSet.contains(captureKey(for: $0)) }
    }

    // Generation range filter
    if let gen = state.selectedGeneration, let range = parseNationalDexRange(gen.nationalDexRange) {
      list = list.filter { range.contains($0.id) }
    }

    state.filtered = list
  }

  // Determine form kind(s) a pokemon belongs to
  private func formKind(of p: Pokemon) -> Set<FormFilter> {
    var kinds: Set<FormFilter> = []
    let type = p.formType?.lowercased() ?? ""
    let hasFormName = (p.formName?.isEmpty == false)
    if type == "mega" { kinds.insert(.mega) }
    if type == "gmax" || type == "gigantamax" { kinds.insert(.gmax) }
    // otherForms: form_name not empty and form_type not in {mega,gmax,alola,galar,hisui,paldea}
    let excluded = ["mega", "gmax", "gigantamax", "alola", "galar", "hisui", "paldea"]
    if hasFormName && !excluded.contains(type) {
      kinds.insert(.otherForms)
    }
    return kinds
  }

  private func captureKey(for p: Pokemon) -> String { "\(p.id)-\(p.subId ?? 0)" }

  private func parseNationalDexRange(_ s: String) -> ClosedRange<Int>? {
    // Extract first two numbers in the string
    // e.g. "#0001 - #0151" -> 1...151
    let numbers = s
      .replacingOccurrences(of: "#", with: "")
      .components(separatedBy: CharacterSet.decimalDigits.inverted)
      .compactMap { Int($0) }
    guard numbers.count >= 2 else { return nil }
    let lower = min(numbers[0], numbers[1])
    let upper = max(numbers[0], numbers[1])
    return lower...upper
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
