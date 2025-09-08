import Foundation

public protocol APIClient {
  func fetchPokemon() async throws -> [Pokemon]
  func fetchGenerations() async throws -> [GenerationCategory]
}

