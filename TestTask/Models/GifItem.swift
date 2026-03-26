//
//  GifItem.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import Foundation

struct GifItem: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let images: GifImages

    var previewURL: URL? {
        URL(string: images.fixedWidth.url)
    }

    var originalURL: URL? {
        URL(string: images.original.url)
    }

    static func == (lhs: GifItem, rhs: GifItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct GifImages: Codable, Sendable {
    let original: GifImageData
    let fixedWidth: GifImageData

    enum CodingKeys: String, CodingKey {
        case original
        case fixedWidth = "fixed_width"
    }
}

struct GifImageData: Codable, Sendable {
    let url: String
    let width: String
    let height: String
}
