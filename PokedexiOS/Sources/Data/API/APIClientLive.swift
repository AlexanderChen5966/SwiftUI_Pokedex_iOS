import Foundation
import Alamofire

public struct APIClientLive: APIClient {
  private let pokemonURL: URL?
  private let generationsURL: URL?

  public init(pokemonURL: URL? = nil, generationsURL: URL? = nil) {
    self.pokemonURL = pokemonURL
    self.generationsURL = generationsURL
  }

  public func fetchPokemon() async throws -> [Pokemon] {
    if let pokemonURL { return try await fetchRemote([Pokemon].self, from: pokemonURL) }
    return try fetchLocalJSON([Pokemon].self, resource: "pokemon_data")
  }

  public func fetchGenerations() async throws -> [GenerationCategory] {
    if let generationsURL { return try await fetchRemote([GenerationCategory].self, from: generationsURL) }
    return try fetchLocalJSON([GenerationCategory].self, resource: "pokemon_generations")
  }

  // MARK: - Helpers

  private func fetchRemote<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .useDefaultKeys

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url)
        .validate()
        .responseDecodable(of: T.self, decoder: decoder) { response in
          switch response.result {
          case let .success(value):
            continuation.resume(returning: value)
          case let .failure(error):
            continuation.resume(throwing: error)
          }
        }
    }
  }

  private func fetchLocalJSON<T: Decodable>(_ type: T.Type, resource: String) throws -> T {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .useDefaultKeys

    guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
      throw NSError(domain: "APIClientLive", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing bundled JSON: \(resource).json"])}
    let data = try Data(contentsOf: url)
    return try decoder.decode(T.self, from: data)
  }
}

