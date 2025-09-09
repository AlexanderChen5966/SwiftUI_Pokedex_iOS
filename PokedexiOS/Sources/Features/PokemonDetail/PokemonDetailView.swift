import SwiftUI
import ComposableArchitecture
import SDWebImageSwiftUI

public struct PokemonDetailView: View {
  let store: StoreOf<PokemonDetailFeature>

  public init(store: StoreOf<PokemonDetailFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          // Large artwork image
          ZStack {
            RoundedRectangle(cornerRadius: 16)
              .fill(Color.gray.opacity(0.08))
              .frame(height: 260)

            if let url = ImageURLBuilder.url(for: viewStore.pokemon.id, style: .officialArtwork) ?? ImageURLBuilder.url(from: viewStore.pokemon.image) {
              WebImage(url: url)
                .resizable()
                .indicator(.activity)
                .scaledToFit()
                .frame(height: 240)
            }
          }

          // Basic Info
          GroupBox("Basic Info") {
            KeyValueRow(key: "ID", value: "#\(viewStore.pokemon.id)")
            if let sub = viewStore.pokemon.subId { KeyValueRow(key: "Sub ID", value: "#\(sub)") }
            KeyValueRow(key: "Name", value: viewStore.pokemon.name)
            if let form = viewStore.pokemon.formName, !form.isEmpty { KeyValueRow(key: "Form", value: form) }
            if let type = viewStore.pokemon.formType, !type.isEmpty { KeyValueRow(key: "Form Type", value: type) }
          }

          // Measurements
          GroupBox("Measurements") {
            if let h = viewStore.pokemon.height { KeyValueRow(key: "Height", value: "\(h)") }
            if let w = viewStore.pokemon.weight { KeyValueRow(key: "Weight", value: "\(w)") }
            if let cat = viewStore.pokemon.category, !cat.isEmpty { KeyValueRow(key: "Category", value: cat) }
            if let gender = viewStore.pokemon.gender, !gender.isEmpty { KeyValueRow(key: "Gender", value: gender) }
          }

          // Collections
          if !viewStore.pokemon.types.isEmpty {
            GroupBox("Types") { TagList(viewStore.pokemon.types) }
          }
          if !viewStore.pokemon.abilities.isEmpty {
            GroupBox("Abilities") { TagList(viewStore.pokemon.abilities) }
          }
          if !viewStore.pokemon.weakness.isEmpty {
            GroupBox("Weakness") { TagList(viewStore.pokemon.weakness) }
          }

          Spacer(minLength: 12)
        }
        .padding()
      }
      .navigationTitle(viewStore.pokemon.name)
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

private struct KeyValueRow: View {
  let key: String
  let value: String
  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(key)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(width: 100, alignment: .leading)
      Text(value)
        .font(.body)
        .foregroundStyle(.primary)
      Spacer()
    }
    .padding(.vertical, 4)
  }
}

private struct TagList: View {
  let items: [String]
  init(_ items: [String]) { self.items = items }

  var body: some View {
    FlexibleHStack(items) { item in
      Text(item)
        .font(.subheadline)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color(.secondarySystemBackground)))
    }
  }
}

// A simple flexible layout to wrap tags.
private struct FlexibleHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
  let data: Data
  let content: (Data.Element) -> Content

  init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
    self.data = data
    self.content = content
  }

  var body: some View {
    var width: CGFloat = 0
    var height: CGFloat = 0

    return GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        ForEach(Array(data), id: \.self) { item in
          content(item)
            .alignmentGuide(.leading, computeValue: { d in
              if abs(width - d.width) > geometry.size.width {
                width = 0
                height -= d.height
              }
              let result = width
              if item == data.last { width = 0 } else { width -= d.width }
              return result
            })
            .alignmentGuide(.top, computeValue: { _ in
              let result = height
              if item == data.last { height = 0 }
              return result
            })
        }
      }
    }
    .frame(maxWidth: .infinity, minHeight: 0)
  }
}

