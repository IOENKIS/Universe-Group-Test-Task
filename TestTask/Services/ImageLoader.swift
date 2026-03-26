//
//  ImageLoader.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import UIKit

// MARK: - ImageLoader

/// Thread-safe async image loader with NSCache.
/// Marked nonisolated so it can be called from any context.
final class ImageLoader: Sendable {

    static let shared = ImageLoader()

    // NSCache is thread-safe internally
    private let cache = NSCache<NSString, UIImage>()

    // Protects activeTasks dictionary
    private let lock = NSLock()
    // nonisolated(unsafe) because we manage access manually via lock
    nonisolated(unsafe) private var activeTasks: [String: Task<UIImage, Error>] = [:]

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    // MARK: - Public API

    nonisolated func loadImage(from url: URL) async throws -> UIImage {
        let key = url.absoluteString as NSString
        let urlString = url.absoluteString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        lock.lock()
        if let existing = activeTasks[urlString] {
            lock.unlock()
            return try await existing.value
        }

        let task = Task<UIImage, Error> { [weak self] in
            guard let self else { throw NetworkError.noData }
            let data = try await NetworkService.shared.fetchData(from: url)
            guard let image = UIImage(data: data) else {
                throw NetworkError.noData
            }
            self.cache.setObject(image, forKey: key, cost: data.count)
            return image
        }

        activeTasks[urlString] = task
        lock.unlock()

        defer {
            lock.lock()
            activeTasks.removeValue(forKey: urlString)
            lock.unlock()
        }

        return try await task.value
    }

    nonisolated func clearCache() {
        cache.removeAllObjects()
        lock.lock()
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        lock.unlock()
    }
}
