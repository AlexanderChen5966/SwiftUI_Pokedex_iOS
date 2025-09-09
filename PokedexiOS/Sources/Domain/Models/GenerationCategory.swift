import Foundation

/// 世代/地區分類資料模型。
/// - 解析 `pokemon_generations.json`，並支援將以逗號分隔的字串轉為陣列。

public struct GenerationCategory: Codable, Equatable, Identifiable {
  public var id: String { "\(generation)|\(region)" }

  public let generation: String
  public let region: String
  public let nationalDexRange: String
  public let versions: [String]
  public let features: [String]

  public init(
    generation: String,
    region: String,
    nationalDexRange: String,
    versions: [String],
    features: [String]
  ) {
    self.generation = generation
    self.region = region
    self.nationalDexRange = nationalDexRange
    self.versions = versions
    self.features = features
  }

  enum CodingKeys: String, CodingKey {
    case generation
    case region
    case nationalDexRange = "national_dex_range"
    case versions
    case features
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.generation = (try? container.decode(String.self, forKey: .generation)) ?? ""
    self.region = (try? container.decode(String.self, forKey: .region)) ?? ""
    self.nationalDexRange = (try? container.decode(String.self, forKey: .nationalDexRange)) ?? ""

    /// 嘗試以陣列解碼；若為單一字串則以逗號切分。
    func decodeStringOrArray(_ key: CodingKeys) -> [String] {
      if let arr = try? container.decodeIfPresent([String].self, forKey: key) { return arr ?? [] }
      if let single = try? container.decodeIfPresent(String.self, forKey: key) { return (single ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
      return []
    }

    self.versions = decodeStringOrArray(.versions)
    self.features = decodeStringOrArray(.features)
  }
}

public extension GenerationCategory {
  /// 從 `Data` 解碼成 `[GenerationCategory]`
  static func decodeList(from data: Data) throws -> [GenerationCategory] {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .useDefaultKeys
    return try decoder.decode([GenerationCategory].self, from: data)
  }
}
