//
//  BigMediaCell.swift
//  CloudMovies
//
//  Created by Artem Bilyi on 07.12.2022.
//

import UIKit
import Kingfisher

final class BigMediaCell: UICollectionViewCell {
    // MARK: identifier
    static let identifier = "bigCellIdentifier"
    // MARK: - MovieCell UI Elements
    private let container = UIView()
    private let posterImage = UIImageView()
    private let title = UILabel()
    private let saveButton = UIButton(type: .custom)
    private let voteAverage = UILabel()
    private let star = UIImageView()
    private lazy var networkManager: NetworkService = {
        return NetworkService()
    }()
    private lazy var alert: AlertCreator = {
        return AlertCreator()
    }()
    var isFavourite = false
    weak var delegate: ViewModelProtocol?
    weak var viewController: UIViewController?
    private var mediaID: Int = 0
    private var mediaType: MediaType?
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        hideButton()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented - not using storyboards")
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
    // MARK: - Configure cell
    private func configureView() {
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        container.contentMode = .scaleAspectFill
        container.backgroundColor = .white
        container.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        container.layer.cornerRadius = 8
        posterImage.translatesAutoresizingMaskIntoConstraints = false
        posterImage.contentMode = .scaleAspectFill
        title.translatesAutoresizingMaskIntoConstraints = false
        title.numberOfLines = 1
        title.textAlignment = .left
        title.textColor = .black
        title.minimumContentSizeCategory = .medium
        title.font = UIFont.preferredFont(forTextStyle: .subheadline)
        star.translatesAutoresizingMaskIntoConstraints = false
        star.contentMode = .scaleAspectFit
        star.image = UIImage(named: "star")
        saveButton.setImage(UIImage(named: "addwatchlist"), for: .normal)
        saveButton.setImage(UIImage(named: "checkmark"), for: .selected)
        saveButton.addTarget(self, action: #selector(saveButtonPressed(_:)), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        voteAverage.font = UIFont.preferredFont(forTextStyle: .caption1)
        voteAverage.textColor = .black
        voteAverage.translatesAutoresizingMaskIntoConstraints = false
        contentView.dropShadow()
    }
    // MARK: - MovieCell Contraints
    private func setupContraints() {
        contentView.addSubview(container)
        container.addSubview(title)
        container.addSubview(star)
        container.addSubview(voteAverage)
        container.addSubview(posterImage)
        container.addSubview(saveButton)
        NSLayoutConstraint.activate([
            container.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
            container.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        ])
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            title.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            title.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        NSLayoutConstraint.activate([
            voteAverage.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            voteAverage.centerYAnchor.constraint(equalTo: title.centerYAnchor)
        ])
        NSLayoutConstraint.activate([
            star.trailingAnchor.constraint(equalTo: voteAverage.leadingAnchor, constant: -8),
            star.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            star.heightAnchor.constraint(equalToConstant: 14),
            star.widthAnchor.constraint(equalToConstant: 14)
        ])
        NSLayoutConstraint.activate([
            posterImage.topAnchor.constraint(equalTo: container.topAnchor),
            posterImage.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            posterImage.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 1),
            posterImage.heightAnchor.constraint(equalTo: posterImage.widthAnchor, multiplier: 0.5625)
        ])
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: container.topAnchor),
            saveButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 40),
            saveButton.widthAnchor.constraint(equalToConstant: 32)
        ])
    }
    private func hideButton() {
        if StorageSecure.keychain["guestID"] != nil {
            saveButton.isHidden = true
        }
    }
    // MARK: - Configure with Kingsfiger
    func bindWithMedia(media: MediaResponse.Media) {
        isFavourite = false
        title.text = media.title ?? media.name
        voteAverage.text = "\(media.voteAverage ?? 0.0)"
        guard let poster = media.backdropPath else { return }
        let url = URL(string: "https://image.tmdb.org/t/p/w780\(poster)")
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
            if let media = mediaType?.rawValue {
                networkManager.actionWatchList(mediaType: media,
                                               mediaID: String(mediaID),
                                               bool: true,
                                               accountID: accountID,
                                               sessionID: sessionID)
                saveButton.isSelected.toggle()
            }
        case true:
            if let media = mediaType?.rawValue {
                let alert = alert.createAlert(mediaType: media, mediaID: String(mediaID), sender: sender)
                viewController?.present(alert, animated: true)
            }
        }
    }
}
