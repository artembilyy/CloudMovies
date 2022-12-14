//
//  HeaderCell.swift
//  CloudMovies
//
//  Created by Артем Билый on 20.10.2022.
//

import UIKit

final class DiscoverHeader: UICollectionViewCell {
    // MARK: - Init UI
    static let identifier = "headerIdentifier"
    private let contrainer = UIView()
    private let leftElemnt = UIView()
    let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented - not using storyboards")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraint()
    }
    // MARK: - Configure UI
    private func configureView() {
        contrainer.backgroundColor = .clear
        contrainer.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textAlignment = .left
        label.adjustsFontForContentSizeCategory = true
        label.minimumContentSizeCategory = .accessibilityMedium
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textColor = .black
        leftElemnt.backgroundColor = .systemRed
        leftElemnt.translatesAutoresizingMaskIntoConstraints = false
        leftElemnt.layer.cornerRadius = 4
    }
    // MARK: - Constraints
    private func setupConstraint() {
        contentView.addSubview(contrainer)
        contrainer.addSubview(leftElemnt)
        contrainer.addSubview(label)
        NSLayoutConstraint.activate([
            contrainer.widthAnchor.constraint(equalToConstant: contentView.bounds.width),
            contrainer.heightAnchor.constraint(equalToConstant: contentView.bounds.height),
            contrainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            contrainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        NSLayoutConstraint.activate([
            leftElemnt.topAnchor.constraint(equalTo: contrainer.topAnchor, constant: 4),
            leftElemnt.leadingAnchor.constraint(equalTo: contrainer.leadingAnchor, constant: 8),
            leftElemnt.bottomAnchor.constraint(equalTo: contrainer.bottomAnchor, constant: -4),
            leftElemnt.widthAnchor.constraint(equalToConstant: 8)
        ])
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leftElemnt.trailingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: leftElemnt.centerYAnchor)
        ])
    }
}
