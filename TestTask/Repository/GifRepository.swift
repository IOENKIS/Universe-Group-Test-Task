//
//  GifRepository.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import Foundation

// MARK: - Protocol

protocol GifRepositoryProtocol: Sendable {
    func fetchTrending(limit: Int, offset: Int) async throws -> [GifItem]
    func search(query: String, limit: Int, offset: Int) async throws -> [GifItem]
}

// MARK: - Implementation

final class GifRepository: GifRepositoryProtocol {

    static let shared = GifRepository()

    private let service: GiphyService

    init(service: GiphyService = .shared) {
        self.service = service
    }

    nonisolated func fetchTrending(limit: Int = 25, offset: Int = 0) async throws -> [GifItem] {
        try await service.fetchTrending(limit: limit, offset: offset)
    }

    nonisolated func search(query: String, limit: Int = 25, offset: Int = 0) async throws -> [GifItem] {
        try await service.search(query: query, limit: limit, offset: offset)
    }
}
