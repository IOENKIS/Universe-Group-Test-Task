//
//  GiphyService.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import Foundation

// MARK: - GiphyError

enum GiphyError: LocalizedError {
    case unauthorized // Error 401: Invalid API key
    case forbidden    // Error 403: Key blocked
    case rateLimit    // Error 429: Too many requests
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Invalid Giphy API key. Please check your settings."
        case .forbidden:    return "Access to Giphy is prohibited."
        case .rateLimit:    return "You have reached the request limit. Please try again later.."
        case .unknown:      return "An unknown Giphy error has occurred."
        }
    }
}

// MARK: - GiphyService

final class GiphyService: Sendable {

    static let shared = GiphyService()

    private let apiKey = "JKgmZsVlSnirgrcJWvPAHPW9rxvRx5Bl"
    private let baseURL = "https://api.giphy.com/v1/gifs"

    private init() {}
    
    // MARK: - Trending

    nonisolated func fetchTrending(limit: Int = 25, offset: Int = 0) async throws -> [GifItem] {
        var components = URLComponents(string: "\(baseURL)/trending")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "limit",   value: "\(limit)"),
            URLQueryItem(name: "offset",  value: "\(offset)"),
            URLQueryItem(name: "rating",  value: "g")
        ]
        guard let url = components.url else { throw NetworkError.invalidURL }
        let response = try await NetworkService.shared.fetch(GifResponse.self, from: url)
        return response.data
    }

    // MARK: - Search

    nonisolated func search(query: String, limit: Int = 25, offset: Int = 0) async throws -> [GifItem] {
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "q",       value: query),
            URLQueryItem(name: "limit",   value: "\(limit)"),
            URLQueryItem(name: "offset",  value: "\(offset)"),
            URLQueryItem(name: "rating",  value: "g"),
            URLQueryItem(name: "lang",    value: "en")
        ]
        guard let url = components.url else { throw NetworkError.invalidURL }
        let response = try await NetworkService.shared.fetch(GifResponse.self, from: url)
        return response.data
    }
}
