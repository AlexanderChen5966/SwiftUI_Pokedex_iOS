import Foundation

/// 單筆寶可夢資料模型。
/// - 對應 `pokemon_data.json` 的欄位，並針對數值型欄位提供寬鬆解碼（字串或數字）。

public struct Pokemon: Codable, Equatable, Identifiable {
  // Core identifiers
  public let id: Int
  public let subId: Int?

  // Basic info
  public let name: String
  public let formName: String?
  public let formType: String?

  // Media / measurements
  public let image: String?
  public let height: Double?
  public let weight: Double?

  // Classification
  public let category: String?
  public let gender: String?

  // Attributes
  public let abilities: [String]
  public let weakness: [String]
  public let types: [String]

  public init(
    id: Int,
    subId: Int? = nil,
    name: String,
    formName: String? = nil,
    formType: String? = nil,
    image: String? = nil,
    height: Double? = nil,
    weight: Double? = nil,
    category: String? = nil,
    gender: String? = nil,
    abilities: [String] = [],
    weakness: [String] = [],
    types: [String] = []
  ) {
    self.id = id
    self.subId = subId
    self.name = name
    self.formName = formName
    self.formType = formType
    self.image = image
    self.height = height
    self.weight = weight
    self.category = category
    self.gender = gender
    self.abilities = abilities
    self.weakness = weakness
    self.types = types
  }

  enum CodingKeys: String, CodingKey {
    case id
    case subId = "sub_id"
    case name
    case formName = "form_name"
    case formType = "form_type"
    case image
    case height
    case weight
    case category
    case gender
    case abilities
    case weakness
    case types
  }

  /// 寬鬆解碼：部分資料源可能將數字以字串形式提供（例如 height/weight）。
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decode(Int.self, forKey: .id)
    self.subId = try? container.decodeIfPresent(Int.self, forKey: .subId)

    self.name = (try? container.decode(String.self, forKey: .name)) ?? ""
    self.formName = try? container.decodeIfPresent(String.self, forKey: .formName)
    self.formType = try? container.decodeIfPresent(String.self, forKey: .formType)
    self.image = try? container.decodeIfPresent(String.self, forKey: .image)

    // height / weight 可能為字串，嘗試轉成 Double
    func decodeFlexibleDouble(_ key: CodingKeys) -> Double? {
      if let d = try? container.decodeIfPresent(Double.self, forKey: key) { return d }
      if let s = try? container.decodeIfPresent(String.self, forKey: key) {
        return Double(s ?? "")
      }
      return nil
    }

    self.height = decodeFlexibleDouble(.height)
    self.weight = decodeFlexibleDouble(.weight)

    self.category = try? container.decodeIfPresent(String.self, forKey: .category)
    self.gender = try? container.decodeIfPresent(String.self, forKey: .gender)

    self.abilities = (try? container.decodeIfPresent([String].self, forKey: .abilities)) ?? []
    self.weakness = (try? container.decodeIfPresent([String].self, forKey: .weakness)) ?? []
    self.types = (try? container.decodeIfPresent([String].self, forKey: .types)) ?? []
  }
}

public extension Pokemon {
  /// 從 `Data` 解碼成 `[Pokemon]`
  static func decodeList(from data: Data) throws -> [Pokemon] {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .useDefaultKeys
    return try decoder.decode([Pokemon].self, from: data)
  }
}
