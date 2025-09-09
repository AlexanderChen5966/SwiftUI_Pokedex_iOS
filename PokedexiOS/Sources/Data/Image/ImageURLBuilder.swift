import Foundation

public struct ImageURLBuilder {
  public enum Style {
    case sprite(isShiny: Bool)
    case officialArtwork
  }

  /// 依照 id 與指定樣式組裝圖片 URL。
  public static func url(for id: Int, style: Style = .officialArtwork) -> URL? {
    switch style {
    case let .sprite(isShiny):
      let shinyPath = isShiny ? "shiny/" : ""
      return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(shinyPath)\(id).png")
    case .officialArtwork:
      return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")
    }
  }

  /// 直接將後端提供的圖片字串轉 URL（空字串會回傳 nil）。
  public static func url(from imageString: String?) -> URL? {
    guard let imageString, !imageString.isEmpty else { return nil }
    return URL(string: imageString)
  }
}
