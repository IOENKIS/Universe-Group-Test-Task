//
//  FavoritesStorage.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import Foundation

// MARK: - FavoritesStorage
//
// Thread-safety model:
//   • `cache` is the source of truth and is always read/written on the main thread.
//   • UserDefaults persistence is offloaded to a serial background queue so the
//     main thread is never blocked by encoding / disk I/O, which eliminates the
//     UI flicker that was visible when toggling favorites.

final class FavoritesStorage {

    static let shared = FavoritesStorage()

    private let defaults = UserDefaults.standard
    private let key = "com.testtask.favorites"

    /// Serial background queue used exclusively for UserDefaults I/O.
    private let persistenceQueue = DispatchQueue(
        label: "com.testtask.favoritesStorage",
        qos: .utility
    )

    /// In-memory cache — keeps reads instantaneous and avoids repeated decoding.
    private var cache: [GifItem]?

    private init() {}

    // MARK: - Public API

    /// All saved favorites. Reads from the in-memory cache; falls back to disk on first access.
    var favorites: [GifItem] {
        if let cache { return cache }
        let loaded = loadSync()
        cache = loaded
        return loaded
    }

    func isFavorite(_ item: GifItem) -> Bool {
        favorites.contains(item)
    }

    func add(_ item: GifItem) {
        guard !isFavorite(item) else { return }
        var updated = favorites
        updated.append(item)
        // Update cache immediately so callers see the new state without waiting for disk.
        cache = updated
        persistAsync(updated)
    }

    func remove(_ item: GifItem) {
        let updated = favorites.filter { $0.id != item.id }
        cache = updated
        persistAsync(updated)
    }

    func toggle(_ item: GifItem) {
        if isFavorite(item) {
            remove(item)
        } else {
            add(item)
        }
    }

    // MARK: - Private helpers

    /// Synchronous disk read used only once (on first access) to warm the cache.
    private func loadSync() -> [GifItem] {
        guard let data = defaults.data(forKey: key),
              let items = try? JSONDecoder().decode([GifItem].self, from: data) else {
            return []
        }
        return items
    }

    /// Encodes and writes `items` on the background queue — never blocks the main thread.
    private func persistAsync(_ items: [GifItem]) {
        persistenceQueue.async { [weak self] in
            guard let self,
                  let data = try? JSONEncoder().encode(items) else { return }
            self.defaults.set(data, forKey: self.key)
        }
    }
}
