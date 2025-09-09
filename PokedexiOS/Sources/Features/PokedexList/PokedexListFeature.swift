import Foundation
import ComposableArchitecture

/// Pokedex 清單頁的商業邏輯（Reducer）。
/// - 管理資料載入、搜尋、篩選（形態 / 收服 / 世代）與圖像樣式。

public struct PokedexListFeature: Reducer {
  public struct State: Equatable {
    // Data
    /// 從資料來源取得的完整清單
    public var all: [Pokemon] = []
    /// 依搜尋與篩選條件計算後的結果
    public var filtered: [Pokemon] = []
    /// 世代/地區資料
    public var generations: [GenerationCategory] = []

    // UI
    @BindingState public var searchText: String = ""
    public var isLoading: Bool = false
    public var imageStyle: ImageStyle = .official
    public var isShiny: Bool = false

    // Filters
    /// 目前選取的世代/地區（以全國編號範圍過濾）
    public var selectedGeneration: GenerationCategory? = nil
    /// 形態篩選：可複選（Mega/Gmax/OtherForms）。空集合代表不套用。
    public var formFilters: Set<FormFilter> = []
    /// 收服篩選：全部/已收服/未收服
    public var captureFilter: CaptureFilter = .all
    /// 已收服集合；鍵值格式："{id}-{sub_id 或 0}"
    public var caughtSet: Set<String> = []

    public init() {}
  }

  /// 清單卡片圖像樣式
  public enum ImageStyle: String, CaseIterable, Equatable {
    case sprite
    case official
  }

  /// 形態篩選種類
  public enum FormFilter: Hashable {
    case mega
    case gmax
    case otherForms
  }

  /// 收服篩選種類
  public enum CaptureFilter: Equatable, CaseIterable {
    case all
    case caught
    case uncaught
  }

    /// 使用者動作與資料回傳事件
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

  /// 依目前 `State` 的搜尋與篩選條件計算 `filtered`。
  private func filter(state: inout State) {
    // 1) 從全部開始
    var list = state.all

    // 2) 搜尋：name / id / types / category（包含式）
    let q = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if !q.isEmpty {
      list = list.filter { p in
        if p.name.lowercased().contains(q) { return true }
        if p.types.joined(separator: ", ").lowercased().contains(q) { return true }
        if let category = p.category?.lowercased(), category.contains(q) { return true }
        return String(p.id).contains(q)
      }
    }

    // 3) 形態：若使用者有選擇任何一種形態，則保留符合任一選擇的項目
    if !state.formFilters.isEmpty {
      list = list.filter { p in
        let kind = formKind(of: p)
        return kind.contains(where: { state.formFilters.contains($0) })
      }
    }

    // 4) 收服：依目前模式過濾
    switch state.captureFilter {
    case .all:
      break
    case .caught:
      list = list.filter { state.caughtSet.contains(captureKey(for: $0)) }
    case .uncaught:
      list = list.filter { !state.caughtSet.contains(captureKey(for: $0)) }
    }

    // 5) 世代/地區：以全國編號範圍過濾
    if let gen = state.selectedGeneration, let range = parseNationalDexRange(gen.nationalDexRange) {
      list = list.filter { range.contains($0.id) }
    }

    state.filtered = list
  }

  /// 判斷寶可夢屬於哪些形態分類（可同時符合多個）
  private func formKind(of p: Pokemon) -> Set<FormFilter> {
    var kinds: Set<FormFilter> = []
    let type = p.formType?.lowercased() ?? ""
    let hasFormName = (p.formName?.isEmpty == false)
    if type == "mega" { kinds.insert(.mega) }
    if type == "gmax" || type == "gigantamax" { kinds.insert(.gmax) }
    // otherForms：form_name 有值且 form_type 不在 {mega, gmax/gigantamax, alola, galar, hisui, paldea}
    let excluded = ["mega", "gmax", "gigantamax", "alola", "galar", "hisui", "paldea"]
    if hasFormName && !excluded.contains(type) {
      kinds.insert(.otherForms)
    }
    return kinds
  }

  /// 產生收服鍵值（以便與 `caughtSet` 比對）
  private func captureKey(for p: Pokemon) -> String { "\(p.id)-\(p.subId ?? 0)" }

  /// 解析字串形式的全國編號範圍（例如："#0001 - #0151"）
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
