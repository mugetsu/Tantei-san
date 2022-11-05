//
//  JikanAPIRequest.swift
//  Tantei
//
//  Created by Randell on 5/11/22.
//

import Foundation

enum JikanAPIRequest {
    case getAnimeBy(id: Int),
         getRelations(id: Int),
         getSchedules,
         topAnime(type: AnimeType, filter: TopAnimeType, limit: Int),
         searchAnimeByTitle(keyword: String)
}

extension JikanAPIRequest: RequestProtocol {
    var path: String {
        switch self {
        case let .getAnimeBy(id):
            return "/anime/\(id)"
        case let .getRelations(id):
            return "/anime/\(id)/relations"
        case .getSchedules:
            return "/schedules"
        case .topAnime:
            return "/top/anime"
        case .searchAnimeByTitle:
            return "/anime"
        }
    }

    var method: RequestMethod {
        switch self {
        case .getAnimeBy:
            return .get
        case .getRelations:
            return .get
        case .getSchedules:
            return .get
        case .topAnime:
            return .get
        case .searchAnimeByTitle:
            return .get
        }
    }

    var headers: ReaquestHeaders? {
        nil
    }

    var parameters: RequestParameters? {
        switch self {
        case .getAnimeBy:
            return nil
        case .getRelations:
            return nil
        case .getSchedules:
            return nil
        case let .topAnime(type, filter, limit):
            return [
                "type": type.rawValue,
                "filter": filter.rawValue,
                "limit": String(limit)
            ]
        case let .searchAnimeByTitle(keyword):
            return [
                "letter": keyword,
                "limit": "1"
            ]
        }
    }

    var requestType: RequestType {
        return .data
    }

    var responseType: ResponseType {
        return .json
    }
}
