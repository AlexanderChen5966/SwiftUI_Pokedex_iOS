import SwiftUI
import ComposableArchitecture
import SDWebImageSwiftUI

/// Pokedex 清單頁面 UI。
/// - 使用 `PokedexListFeature` 的狀態驅動：搜尋、篩選、圖像樣式與閃光切換。

public struct PokedexListView: View {
  let store: StoreOf<PokedexListFeature>

  public init(store: StoreOf<PokedexListFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ScrollView {
        // 兩欄圖片清單
        LazyVGrid(columns: [
          GridItem(.flexible(minimum: 120, maximum: 200), spacing: 12),
          GridItem(.flexible(minimum: 120, maximum: 200), spacing: 12)
        ], spacing: 12) {
          ForEach(viewStore.ids, id: \.self) { id in
            ImageCardView(id: id, imageStyle: viewStore.imageStyle, isShiny: viewStore.isShiny)
          }
        }
        .padding(.horizontal)
      }
      .navigationTitle("Pokédex")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            // 圖像樣式與閃光
            Picker("Image Style", selection: viewStore.binding(get: \.imageStyle, send: PokedexListFeature.Action.setImageStyle)) {
              Text("Official").tag(PokedexListFeature.ImageStyle.official)
              Text("Sprite").tag(PokedexListFeature.ImageStyle.sprite)
            }
            Toggle("Shiny", isOn: viewStore.binding(get: \.isShiny, send: PokedexListFeature.Action.toggleShiny))
          } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
          }
        }
      }
      .task { viewStore.send(.onAppear) }
    }
  }
}

public struct ImageCardView: View {
  let id: Int
  let imageStyle: PokedexListFeature.ImageStyle
  let isShiny: Bool

  public var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.gray.opacity(0.08))
        .frame(height: 140)

      if let url = imageURL() {
        WebImage(url: url)
          .resizable()
          .indicator(.activity)
          .scaledToFit()
          .frame(height: 130)
      }
    }
    .padding(6)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(Color(.secondarySystemBackground))
    )
  }

  /// 依當前圖像樣式與是否閃光，回傳顯示用圖片 URL。
  private func imageURL() -> URL? {
    switch imageStyle {
    case .official:
      return ImageURLBuilder.url(for: id, style: .officialArtwork)
    case .sprite:
      return ImageURLBuilder.url(for: id, style: .sprite(isShiny: isShiny))
    }
  }
}
