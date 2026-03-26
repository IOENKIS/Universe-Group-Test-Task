//
//  ImageLoader.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import UIKit
import ImageIO

// MARK: - ImageLoader

/// Thread-safe async image loader with NSCache.
/// Decodes animated GIFs via ImageIO so UIImageView plays them automatically.
final class ImageLoader: Sendable {

    static let shared = ImageLoader()

    // NSCache is thread-safe internally
    private let cache = NSCache<NSString, UIImage>()

    // Protects activeTasks dictionary
    private let lock = NSLock()
    // nonisolated(unsafe) because we manage access manually via lock
    nonisolated(unsafe) private var activeTasks: [String: Task<UIImage, Error>] = [:]

    private init() {
        cache.countLimit = 150
        cache.totalCostLimit = 80 * 1024 * 1024 // 80 MB (animated frames need more room)
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
            guard let image = Self.decodeImage(from: data) else {
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

    // MARK: - GIF Decoding

    /// Decodes data into an animated UIImage when the source contains multiple frames
    /// (e.g. GIF), otherwise falls back to a plain UIImage.
    private static func decodeImage(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }

        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 1 else {
            return UIImage(data: data)
        }

        var frames: [UIImage] = []
        var totalDuration: TimeInterval = 0

        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))

            // Read per-frame delay from GIF metadata
            let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any]
            let gifProps = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay =
                (gifProps?[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval) ??
                (gifProps?[kCGImagePropertyGIFDelayTime] as? TimeInterval) ??
                0.1
            totalDuration += max(delay, 0.02) // enforce minimum 20 ms/frame
        }

        guard !frames.isEmpty else { return UIImage(data: data) }
        return UIImage.animatedImage(with: frames, duration: totalDuration) ?? UIImage(data: data)
    }

    nonisolated func clearCache() {
        cache.removeAllObjects()
        lock.lock()
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        lock.unlock()
    }
}
