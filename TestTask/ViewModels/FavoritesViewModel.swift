//
//  FavoritesViewModel.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import Foundation

// MARK: - FavoritesViewModel

@MainActor
final class FavoritesViewModel {

    // MARK: - Bindings

    var onItemsUpdated: (() -> Void)?

    // MARK: - State

    private(set) var items: [GifItem] = []

    // MARK: - Dependency

    private let storage: FavoritesStorage

    init(storage: FavoritesStorage = .shared) {
        self.storage = storage
    }

    // MARK: - Public API

    func reloadFavorites() {
        items = storage.favorites
        onItemsUpdated?()
    }

    func removeItem(at index: Int) {
        guard index < items.count else { return }
        storage.remove(items[index])
        items.remove(at: index)
        // NOTE: onItemsUpdated is NOT called here intentionally.
        // The ViewController handles the visual removal via performBatchUpdates.
        // Calling reloadData() here alongside deleteItems() would cause a crash
        // due to data source / collection view count inconsistency.
    }

    func isFavorite(at index: Int) -> Bool {
        guard index < items.count else { return false }
        return storage.isFavorite(items[index])
    }
}
