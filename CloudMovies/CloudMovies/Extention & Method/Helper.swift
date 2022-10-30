//
//  Helper.swift
//  CloudMovies
//
//  Created by Артем Билый on 26.10.2022.
//

import Foundation

protocol ViewModelProtocol: AnyObject {
    func showLoading()
    func hideLoading()
    func updateView()
}

extension ViewModelProtocol {
    func showLoading() { }
    func hideLoading() { }
    func updateView() { }
}

public enum MediaType: String {
    case movie
    case tv
}

public enum MediaSection: String {
    case popular
    case topRated   = "top_rated"
    case nowPlaying = "now_playing"
    case upcoming
}

public enum MovieSection: String, CaseIterable {
    case onGoing = "Featured today"
    case upcoming = "Upcoming"
    case popular = "Fan favorites"
    case topRated = "Top rated"
}

public enum MovieSectionNumber: Int {
    case onGoing
    case upcoming
    case popular
    case topRated
}