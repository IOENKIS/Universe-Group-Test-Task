//
//  FavoritesStorage.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import Foundation

// MARK: - FavoritesStorage

final class FavoritesStorage {

    static let shared = FavoritesStorage()

    private let defaults = UserDefaults.standard
    private let key = "com.testtask.favorites"

    private init() {}

    // MARK: - Public API

    var favorites: [GifItem] {
        get { load() }
        set { save(newValue) }
    }

    func isFavorite(_ item: GifItem) -> Bool {
        favorites.contains(item)
    }

    func add(_ item: GifItem) {
        guard !isFavorite(item) else { return }
        var current = favorites
        current.append(item)
        favorites = current
    }

    func remove(_ item: GifItem) {
        favorites = favorites.filter { $0.id != item.id }
    }

    func toggle(_ item: GifItem) {
        if isFavorite(item) {
            remove(item)
        } else {
            add(item)
        }
    }

    // MARK: - Private helpers

    private func load() -> [GifItem] {
        guard let data = defaults.data(forKey: key),
              let items = try? JSONDecoder().decode([GifItem].self, from: data) else {
            return []
        }
        return items
    }

    private func save(_ items: [GifItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: key)
    }
}
