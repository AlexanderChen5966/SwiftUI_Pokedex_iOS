import SwiftUI
import ComposableArchitecture
import SDWebImageSwiftUI

public struct PokedexListView: View {
  let store: StoreOf<PokedexListFeature>

  public init(store: StoreOf<PokedexListFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ScrollView {
        LazyVGrid(columns: [
          GridItem(.flexible(minimum: 120, maximum: 200), spacing: 12),
          GridItem(.flexible(minimum: 120, maximum: 200), spacing: 12)
        ], spacing: 12) {
          ForEach(viewStore.filtered) { pokemon in
            PokemonCardView(
              pokemon: pokemon,
              imageStyle: viewStore.imageStyle,
              isShiny: viewStore.isShiny
            )
          }
        }
        .padding(.horizontal)
      }
      .overlay(alignment: .center) {
        if viewStore.isLoading {
          ProgressView()
        }
      }
      .navigationTitle("Pokédex")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
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
      .searchable(text: viewStore.$searchText, placement: .navigationBarDrawer(displayMode: .always))
      .refreshable {
        viewStore.send(.refreshPulled)
      }
      .task { viewStore.send(.onAppear) }
    }
  }
}

public struct PokemonCardView: View {
  let pokemon: Pokemon
  let imageStyle: PokedexListFeature.ImageStyle
  let isShiny: Bool

  public init(pokemon: Pokemon, imageStyle: PokedexListFeature.ImageStyle, isShiny: Bool) {
    self.pokemon = pokemon
    self.imageStyle = imageStyle
    self.isShiny = isShiny
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ZStack {
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.gray.opacity(0.08))
          .frame(height: 120)

        if let url = imageURL() {
          WebImage(url: url)
            .resizable()
            .indicator(.activity)
            .scaledToFit()
            .frame(height: 110)
        }
      }

      Text(pokemon.name)
        .font(.headline)
        .foregroundStyle(.primary)

      if !pokemon.types.isEmpty {
        Text(pokemon.types.joined(separator: ", "))
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(Color(.secondarySystemBackground))
    )
  }

  private func imageURL() -> URL? {
    switch imageStyle {
    case .official:
      return ImageURLBuilder.url(for: pokemon.id, style: .officialArtwork)
    case .sprite:
      return ImageURLBuilder.url(for: pokemon.id, style: .sprite(isShiny: isShiny))
    }
  }
}
