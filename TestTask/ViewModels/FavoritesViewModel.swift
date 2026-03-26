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
        onItemsUpdated?()
    }

    func isFavorite(at index: Int) -> Bool {
        guard index < items.count else { return false }
        return storage.isFavorite(items[index])
    }
}
