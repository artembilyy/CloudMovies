//
//  SearchMovieCell.swift
//  CloudMovies
//
//  Created by Артем Билый on 26.10.2022.
//

import UIKit
import Kingfisher

final class SearchCell: UITableViewCell {
    // MARK: - cell identifier
    static let identifier = "SearchResultTableViewCell"
    // MARK: - MovieCell UI Elements
    private let container = UIView()
    private let posterImage = UIImageView()
    private let title = UILabel()
    private let saveButton = UIButton(type: .custom)
    private let voteAverage = UILabel()
    private let star = UIImageView()
    private let overview = UILabel()
    weak var delegate: ViewModelProtocol?
    private var mediaType: MediaType?
    weak var viewController: UIViewController?
    private var mediaID: Int = 0
    private var isFavourite: Bool = false
    private lazy var networkManager: NetworkService = {
        return NetworkService()
    }()
    private lazy var alert: AlertCreator = {
        return AlertCreator()
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
        hideButton()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        setupContraints()
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        isFavourite = false
        saveButton.isSelected = false
    }
    // MARK: - ConfigureCell
    private func configureView() {
        contentView.addSubview(posterImage)
        contentView.addSubview(title)
        contentView.addSubview(saveButton)
        contentView.addSubview(overview)
        contentView.addSubview(star)
        contentView.addSubview(voteAverage)
        // poster
        posterImage.translatesAutoresizingMaskIntoConstraints = false
        posterImage.contentMode = .scaleAspectFit
        // title
        title.translatesAutoresizingMaskIntoConstraints = false
        title.numberOfLines = 2
        title.textAlignment = .left
        title.textColor = .black
        title.font = UIFont.boldSystemFont(ofSize: 20)
        title.adjustsFontForContentSizeCategory = true
        // star
        star.translatesAutoresizingMaskIntoConstraints = false
        star.contentMode = .scaleAspectFit
        star.image = UIImage(named: "star")
        // save button
        saveButton.setImage(UIImage(named: "addwatchlist"), for: .normal)
        saveButton.setImage(UIImage(named: "checkmark"), for: .selected)
        saveButton.addTarget(self, action: #selector(saveButtonPressed(_:)), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        // voteaverage
        voteAverage.font = UIFont.systemFont(ofSize: 12)
        voteAverage.textColor = .black
        voteAverage.translatesAutoresizingMaskIntoConstraints = false
        // overview
        overview.translatesAutoresizingMaskIntoConstraints = false
        overview.numberOfLines = 6
        overview.textAlignment = .left
        overview.adjustsFontForContentSizeCategory = true
        overview.font = UIFont.systemFont(ofSize: 14)
        overview.textColor = .systemGray
    }
    // MARK: - MovieCell Contraints
    private func setupContraints() {
        NSLayoutConstraint.activate([
            posterImage.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            posterImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            posterImage.widthAnchor.constraint(equalTo: posterImage.heightAnchor, multiplier: 0.66)
        ])
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            title.leadingAnchor.constraint(equalTo: posterImage.trailingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: posterImage.topAnchor, constant: 3),
            saveButton.leadingAnchor.constraint(equalTo: posterImage.leadingAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 38),
            saveButton.widthAnchor.constraint(equalToConstant: 32)
        ])
        NSLayoutConstraint.activate([
            overview.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            overview.leadingAnchor.constraint(equalTo: posterImage.trailingAnchor, constant: 16),
            overview.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        NSLayoutConstraint.activate([
            star.leadingAnchor.constraint(equalTo: posterImage.trailingAnchor, constant: 16),
            star.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            star.heightAnchor.constraint(equalToConstant: 16),
            star.widthAnchor.constraint(equalToConstant: 16)
        ])
        NSLayoutConstraint.activate([
            voteAverage.leadingAnchor.constraint(equalTo: star.trailingAnchor, constant: 4),
            voteAverage.centerYAnchor.constraint(equalTo: star.centerYAnchor)
        ])
    }
    private func hideButton() {
        if StorageSecure.keychain["guestID"] != nil {
            saveButton.isHidden = true
        }
    }
    // MARK: - Test Kingfisher
    func bindWithViewMedia(media: MediaResponse.Media) {
        title.text = media.title ?? media.name
        voteAverage.text = "\(round(media.voteAverage ?? 0.0))"
        overview.text = media.overview
        let url = URL(string: "https://image.tmdb.org/t/p/w500\(media.posterPath ?? "")")
        posterImage.kf.indicatorType = .activity
        posterImage.kf.setImage(with: url)
        mediaID = media.id ?? 0
        if media.title != nil {
            mediaType = MediaType.movie
            for int in CheckInWatchList.shared.movieList where media.id == int {
                isFavourite = true
            }
        } else {
            mediaType = MediaType.tvShow
            for int in CheckInWatchList.shared.tvShowList where media.id == int {
                isFavourite = true
            }
        }
        if isFavourite == true {
            saveButton.isSelected = true
        }
    }
    // MARK: - Select for save/delete item
    @objc func saveButtonPressed(_ sender: UIButton) {
        guard let accountID = StorageSecure.keychain["accountID"],
              let sessionID = StorageSecure.keychain["sessionID"] else { return }
        switch sender.isSelected {
        case false:
            networkManager.actionWatchList(mediaType: mediaType!.rawValue,
                                           mediaID: String(mediaID),
                                           bool: true,
                                           accountID: accountID,
                                           sessionID: sessionID)
            saveButton.isSelected.toggle()
        case true:
            let alert = alert.createAlert(mediaType: mediaType!.rawValue, mediaID: String(mediaID), sender: sender)
            viewController?.present(alert, animated: true)
        }
    }
}
