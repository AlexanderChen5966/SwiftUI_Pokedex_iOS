import Foundation

public struct ImageURLBuilder {
  public enum Style {
    case sprite(isShiny: Bool)
    case officialArtwork
  }

  public static func url(for id: Int, style: Style = .officialArtwork) -> URL? {
    switch style {
    case let .sprite(isShiny):
      let shinyPath = isShiny ? "shiny/" : ""
      return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(shinyPath)\(id).png")
    case .officialArtwork:
      return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")
    }
  }

  public static func url(from imageString: String?) -> URL? {
    guard let imageString, !imageString.isEmpty else { return nil }
    return URL(string: imageString)
  }
}

