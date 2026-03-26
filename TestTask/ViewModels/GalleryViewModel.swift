//
//  GalleryViewModel.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import Foundation
import UIKit

// MARK: - GalleryViewModel

@MainActor
final class GalleryViewModel {

    // MARK: - Bindings

    var onItemsUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    // MARK: - State

    private(set) var items: [GifItem] = []
    private(set) var isLoading = false
    private(set) var currentQuery: String = ""
    private var currentOffset = 0
    private let pageSize = 25
    private var canLoadMore = true

    // MARK: - Dependencies

    private let repository: any GifRepositoryProtocol
    private let storage: FavoritesStorage
    private var loadTask: Task<Void, Never>?

    // MARK: - Init

    init(
        repository: any GifRepositoryProtocol = GifRepository.shared,
        storage: FavoritesStorage = .shared
    ) {
        self.repository = repository
        self.storage = storage
    }

    // MARK: - Public API

    func loadInitial() {
        reset()
        loadNextPage()
    }

    func search(query: String) {
        currentQuery = query.trimmingCharacters(in: .whitespaces)
        reset()
        loadNextPage()
    }

    func loadNextPageIfNeeded(indexPath: IndexPath) {
        guard indexPath.item >= items.count - 4 else { return }
        loadNextPage()
    }

    func toggleFavorite(at index: Int) {
        guard index < items.count else { return }
        storage.toggle(items[index])
    }

    func isFavorite(at index: Int) -> Bool {
        guard index < items.count else { return false }
        return storage.isFavorite(items[index])
    }

    func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        // NOTE: onItemsUpdated is NOT called here intentionally.
        // The ViewController handles the visual removal via performBatchUpdates.
        // Calling reloadData() here alongside deleteItems() would cause a crash
        // due to data source / collection view count inconsistency.
    }

    // MARK: - Private

    private func reset() {
        loadTask?.cancel()
        items = []
        currentOffset = 0
        canLoadMore = true
    }

    private func loadNextPage() {
        guard !isLoading, canLoadMore else { return }
        setLoading(true)

        let query = currentQuery
        let offset = currentOffset
        let limit = pageSize

        loadTask = Task {
            do {
                let fetched: [GifItem]
                if query.isEmpty {
                    fetched = try await self.repository.fetchTrending(limit: limit, offset: offset)
                } else {
                    fetched = try await self.repository.search(query: query, limit: limit, offset: offset)
                }

                guard !Task.isCancelled else { return }

                self.items.append(contentsOf: fetched)
                self.currentOffset += fetched.count
                self.canLoadMore = fetched.count == limit
                self.setLoading(false)
                self.onItemsUpdated?()
            } catch {
                guard !Task.isCancelled else { return }
                self.setLoading(false)
                self.onError?(error.localizedDescription)
            }
        }
    }

    private func setLoading(_ value: Bool) {
        isLoading = value
        onLoadingChanged?(value)
    }
}
