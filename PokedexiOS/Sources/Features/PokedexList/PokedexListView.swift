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
            NavigationLink {
              PokemonDetailView(
                store: Store(
                  initialState: PokemonDetailFeature.State(pokemon: pokemon)
                ) {
                  PokemonDetailFeature()
                }
              )
            } label: {
              PokemonCardView(
                pokemon: pokemon,
                imageStyle: viewStore.imageStyle,
                isShiny: viewStore.isShiny
              )
            }
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
            // Image style & shiny
            Picker("Image Style", selection: viewStore.binding(get: \.imageStyle, send: PokedexListFeature.Action.setImageStyle)) {
              Text("Official").tag(PokedexListFeature.ImageStyle.official)
              Text("Sprite").tag(PokedexListFeature.ImageStyle.sprite)
            }
            Toggle("Shiny", isOn: viewStore.binding(get: \.isShiny, send: PokedexListFeature.Action.toggleShiny))

            // Filters: Forms
            Menu("Forms") {
              Toggle(
                "Mega",
                isOn: Binding(
                  get: { viewStore.formFilters.contains(.mega) },
                  set: { viewStore.send(.toggleFormFilter(.mega, $0)) }
                )
              )
              Toggle(
                "Gmax",
                isOn: Binding(
                  get: { viewStore.formFilters.contains(.gmax) },
                  set: { viewStore.send(.toggleFormFilter(.gmax, $0)) }
                )
              )
              Toggle(
                "Other Forms",
                isOn: Binding(
                  get: { viewStore.formFilters.contains(.otherForms) },
                  set: { viewStore.send(.toggleFormFilter(.otherForms, $0)) }
                )
              )
            }

            // Filters: Capture
            Menu("Capture") {
              Button(action: { viewStore.send(.setCaptureFilter(.all)) }) {
                HStack {
                  if viewStore.captureFilter == .all { Image(systemName: "checkmark") }
                  Text("All")
                }
              }
              Button(action: { viewStore.send(.setCaptureFilter(.caught)) }) {
                HStack {
                  if viewStore.captureFilter == .caught { Image(systemName: "checkmark") }
                  Text("Caught")
                }
              }
              Button(action: { viewStore.send(.setCaptureFilter(.uncaught)) }) {
                HStack {
                  if viewStore.captureFilter == .uncaught { Image(systemName: "checkmark") }
                  Text("Uncaught")
                }
              }
            }

            // Filters: Generation / Region
            Menu("Generation/Region") {
              Button(action: { viewStore.send(.setSelectedGeneration(nil)) }) {
                HStack {
                  if viewStore.selectedGeneration == nil { Image(systemName: "checkmark") }
                  Text("All Generations")
                }
              }
              if !viewStore.generations.isEmpty {
                ForEach(viewStore.generations) { gen in
                  Button(action: { viewStore.send(.setSelectedGeneration(gen)) }) {
                    HStack {
                      if viewStore.selectedGeneration == gen { Image(systemName: "checkmark") }
                      Text("\(gen.generation) · \(gen.region)")
                    }
                  }
                }
              }
            }
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
