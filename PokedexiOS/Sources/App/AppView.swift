import SwiftUI
import ComposableArchitecture
import Alamofire
import SDWebImageSwiftUI

struct AppView: View {
  let store: StoreOf<AppFeature>

  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      NavigationStack {
        VStack(spacing: 16) {
          Text("PokedexiOS")
            .font(.largeTitle)
            .bold()

          Text("Count: \(viewStore.count)")

          Button("Increment") {
            viewStore.send(.incrementButtonTapped)
          }
          .buttonStyle(.borderedProminent)

          if let url = viewStore.imageURL {
            WebImage(url: url)
              .resizable()
//              .placeholder { Rectangle().foregroundColor(.gray.opacity(0.15)) }
              .indicator(.activity)
              .scaledToFit()
              .frame(height: 140)
              .clipShape(RoundedRectangle(cornerRadius: 12))
          }

          Button("Sample Request with Alamofire") {
            AF.request("https://pokeapi.co/api/v2/pokemon/1").response { _ in
              // Intentionally ignore the result; showcase dependency usage
            }
          }
          .buttonStyle(.bordered)

          // Pokedex list
          PokedexListView(
            store: self.store.scope(state: \.list, action: AppFeature.Action.list)
          )

          Spacer()
        }
        .padding()
        .navigationTitle("Pokedex")
      }
    }
  }
}
