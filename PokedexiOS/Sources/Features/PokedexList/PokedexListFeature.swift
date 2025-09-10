import Foundation
import ComposableArchitecture

/// Pokedex 清單頁（僅顯示圖片）。
/// - 不再使用 pokemon_data.json / pokemon_generations.json。
public struct PokedexListFeature: Reducer {
  public struct State: Equatable {
    /// 要顯示的全國編號清單（預設 #0001 - #0151）
    public var ids: [Int] = Array(1...151)

    /// UI
    public var imageStyle: ImageStyle = .official
    public var isShiny: Bool = false

    public init() {}
  }

  /// 圖片樣式
  public enum ImageStyle: String, CaseIterable, Equatable {
    case sprite
    case official
  }

  /// 動作
  public enum Action: Equatable {
    case onAppear
    case setImageStyle(ImageStyle)
    case toggleShiny(Bool)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // 不需載入資料
        return .none

      case let .setImageStyle(style):
        state.imageStyle = style
        return .none

      case let .toggleShiny(on):
        state.isShiny = on
        return .none
      }
    }
  }
}
