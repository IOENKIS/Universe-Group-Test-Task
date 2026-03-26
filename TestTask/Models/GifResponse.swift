//
//  GifResponse.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import Foundation

struct GifResponse: Codable, Sendable {
    let data: [GifItem]
    let pagination: Pagination
    let meta: Meta
}

struct Pagination: Codable, Sendable {
    let totalCount: Int
    let count: Int
    let offset: Int

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case count
        case offset
    }
}

struct Meta: Codable, Sendable {
    let status: Int
    let msg: String
    let responseId: String

    enum CodingKeys: String, CodingKey {
        case status
        case msg
        case responseId = "response_id"
    }
}
