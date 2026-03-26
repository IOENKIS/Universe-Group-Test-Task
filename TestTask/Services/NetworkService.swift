//
//  NetworkService.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import Foundation

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case decodingFailed(Error)
    case noData
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "Invalid URL"
        case .invalidResponse:       return "Invalid server response"
        case .statusCode(let code):  return "Server returned status code \(code)"
        case .decodingFailed(let e): return "Decoding error: \(e.localizedDescription)"
        case .noData:                return "No data received"
        case .unknown(let e):        return e.localizedDescription
        }
    }
}

// MARK: - NetworkService

final class NetworkService: Sendable {

    static let shared = NetworkService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Generic fetch with async/await

    nonisolated func fetch<T: Decodable & Sendable>(_ type: T.Type, from url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.statusCode(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    // MARK: - Raw data fetch

    nonisolated func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.statusCode(httpResponse.statusCode)
        }
        guard !data.isEmpty else {
            throw NetworkError.noData
        }

        return data
    }
}
