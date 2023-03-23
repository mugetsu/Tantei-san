//
//  DashboardViewModel.swift
//  Tantei
//
//  Created by Randell on 1/10/22.
//

import Combine
import Foundation

final class DashboardViewModel {
    private var viewModelEvent = PassthroughSubject<DashboardEvents.ViewModelEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let jikan = JikanAPI()
    private var topAnimes: [Jikan.AnimeDetails] = []
    private var categoryTitles: [String] {
        var titles: [String] = []
        Jikan.TopAnimeType.allCases.forEach { type in
            titles.append(type.description)
        }
        return titles
    }
    
    func bind(_ uiEvents: AnyPublisher<DashboardEvents.UIEvent, Never>) -> AnyPublisher<DashboardEvents.ViewModelEvent, Never> {
        uiEvents.sink { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .viewDidLoad:
                self.fetchData()
            case let .getAnimeDetails(index):
                let anime = Common.createAnimeModel(with: self.topAnimes[index])
                self.viewModelEvent.send(.showAnimeDetails(anime))
            case let .changedCategory(category):
                Task {
                    self.showUpdatedTopAnimes(category)
                }
            }
        }.store(in: &cancellables)
        return viewModelEvent.eraseToAnyPublisher()
    }
    
    private func fetchData() {
        Task {
            do {
                let defaultTopAnimes = try await jikan.getTopAnimes(
                    type: .tv,
                    filter: .airing,
                    limit: 10
                )
                let updatedTopAnimes = try await checkIfHasLazySynopsis(
                    from: defaultTopAnimes ?? []
                )
                topAnimes = updatedTopAnimes
                viewModelEvent.send(.fetchSuccess(topAnimes: topAnimes))
            } catch {
                viewModelEvent.send(.fetchFailed)
            }
        }
    }
    
    private func showUpdatedTopAnimes(_ category: Jikan.TopAnimeType) {
        Task {
            do {
                let defaultTopAnimes = try await jikan.getTopAnimes(
                    type: .tv,
                    filter: category,
                    limit: 10
                )
                let updatedTopAnimes = try await checkIfHasLazySynopsis(
                    from: defaultTopAnimes ?? []
                )
                topAnimes = updatedTopAnimes
                viewModelEvent.send(.showUpdatedTopAnimes(topAnimes))
            } catch {
                viewModelEvent.send(.fetchFailed)
            }
        }
    }
    
    private func checkIfHasLazySynopsis(from animes: [Jikan.AnimeDetails]) async throws -> [Jikan.AnimeDetails] {
        // MARK: Removed the async task group implementation
        // because Jikan API only accepts 3 API calls per second
        // I need to atleast wait 0.5 seconds to accomodate 3 API calls per second
        // to fill the lazy synopsis with the original synopsis
        // for better content display
        var updatedAnimes: [Jikan.AnimeDetails] = animes
        for anime in animes {
            let minimumCount = 164
            let synopsis = anime.synopsis ?? ""
            let isLazySynopsis = synopsis.count <= minimumCount
            if isLazySynopsis {
                let newSynopsis = await self.getOriginalSynopsis(from: synopsis)
                if let index = updatedAnimes.firstIndex(where: { AnimeDetails -> Bool in
                    AnimeDetails.id == anime.id
                }) {
                    updatedAnimes[index].synopsis = newSynopsis
                }
            }
        }
        return updatedAnimes
    }
    
    private func getOriginalSynopsis(from lazySynopsis: String) async -> String? {
        let matches = lazySynopsis.match(
            Jikan.Matcher.getTitleFromLazySynopsis.rawValue,
            options: [.caseInsensitive]
        )
        let flatten = Array(matches.joined())
        guard let lazySynopsisWithTitle = flatten.first else {
            return lazySynopsis
        }
        let originalAnimeTitle = String(
            lazySynopsisWithTitle
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            let matchedAnime = try await self.jikan.searchAnimeByTitle(using: originalAnimeTitle)
            let originalSynopsis = Common.trimSynopsis(from: matchedAnime?.synopsis ?? lazySynopsis)
            return originalSynopsis
        } catch {
            return lazySynopsis
        }
    }
    
    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let newDay = 0
        let noon = 12
        let sunset = 18
        let midnight = 24
        var greetingText = "Hello"
        switch hour {
        case newDay..<noon:
            greetingText = "Good\nMorning"
        case noon..<sunset:
            greetingText = "Good\nAfternoon"
        case sunset..<midnight:
            greetingText = "Good\nEvening"
        default:
            break
        }
        return greetingText
    }
    
    func getCategories() -> [String] {
        return categoryTitles
    }
}

enum DashboardEvents {
    enum UIEvent {
        case viewDidLoad
        case getAnimeDetails(index: Int)
        case changedCategory(_ category: Jikan.TopAnimeType)
    }
    
    enum ViewModelEvent {
        case fetchSuccess(topAnimes: [Jikan.AnimeDetails])
        case fetchFailed
        case showAnimeDetails(_ details: Anime)
        case showUpdatedTopAnimes(_ topAnimes: [Jikan.AnimeDetails])
    }
}
