//
//  GenreListController.swift
//  CloudMovies
//
//  Created by Артем Билый on 03.10.2022.
//

import UIKit

final class DiscoverViewController: UIViewController {
    // view model
    lazy var viewModel = DiscoverViewModel()
    // MARK: - UI
    private let blur: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()
    private lazy var colletionView: UICollectionView = {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        return collectionView
    }()
    private let customSegmentedControl: CustomSegmentedControl = {
        let control = CustomSegmentedControl()
        control.setButtonTitles(buttonTitles: ["Discover", "Movies", "TV Shows"])
        control.backgroundColor = .clear
        return control
    }()
    private lazy var refreshControl = UIRefreshControl()
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNotification()
        updateSavedList()
        loadMovies()
        delegate()
        setupUI()
    }
    override func viewDidLayoutSubviews() {
        setupLayout()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSavedList()
    }
    // MARK: - Delegate
    private func delegate() {
        colletionView.delegate = self
        colletionView.dataSource = self
        colletionView.register(MediaCell.self, forCellWithReuseIdentifier: MediaCell.identifier)
        colletionView.register(BigMediaCell.self, forCellWithReuseIdentifier: BigMediaCell.identifier)
        colletionView.register(DiscoverHeader.self,
                               forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                               withReuseIdentifier: DiscoverHeader.identifier)
        viewModel.delegate = self
    }
    // MARK: - Configure UI
    private func setupUI() {
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.title = "Cloud Movies"
        colletionView.translatesAutoresizingMaskIntoConstraints = false
        colletionView.backgroundColor = #colorLiteral(red: 0.9531050324, green: 0.9531050324, blue: 0.9531050324, alpha: 1)
        view.addSubview(colletionView)
        view.addSubview(blur)
        colletionView.showsVerticalScrollIndicator = true
        customSegmentedControl.delegate = self
        customSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customSegmentedControl)
        refreshControl.tintColor = UIColor.systemRed
        refreshControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        colletionView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
    }
    // MARK: - Load full medias
    private func loadMovies() {
        viewModel.getDiscoverScreen()
        viewModel.getSortedMovies()
        viewModel.getSortedTVShows()
    }
    // MARK: - Configure layout
    private func setupLayout() {
        NSLayoutConstraint.activate([
            colletionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            colletionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            colletionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            colletionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        NSLayoutConstraint.activate([
            customSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customSegmentedControl.heightAnchor.constraint(equalToConstant: 50)
        ])
        NSLayoutConstraint.activate([
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.heightAnchor.constraint(equalTo: tabBarController!.tabBar.heightAnchor, multiplier: 1)
        ])
    }
    // MARK: - CompositionalLayout switch
    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            if self.customSegmentedControl.selectedIndex == 0 && (sectionNumber == 0 || sectionNumber == 1) {
                return self.colletionView.trendingMovies()
            } else {
                return self.colletionView.createLayout()
            }
        }
    }
    // MARK: - Download new list
    private func updateSavedList() {
        CheckInWatchList.shared.getMoviesID {
            self.colletionView.reloadData()
        }
        CheckInWatchList.shared.getTVShowsID {
            self.colletionView.reloadData()
        }
    }
    // MARK: - Refresh
    @objc func pullToRefresh(_ sender: UIButton) {
        loadMovies()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.refreshControl.endRefreshing()
        }
    }
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .reloadData, object: nil)
    }
    @objc
    private func reloadData() {
        colletionView.reloadData()
    }
}
// MARK: - DataSource
extension DiscoverViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch customSegmentedControl.selectedIndex {
        case 0:
            return MovieSection.allCases.count
        case 1:
            return viewModel.sortedMovies.keys.count
        case 2:
            return viewModel.sortedTVShow.keys.count
        default:
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        let section = MovieSectionNumber(rawValue: section)
        switch customSegmentedControl.selectedIndex {
        case 0:
            switch section {
            case .onGoing:
                return viewModel.onGoind.count
            case .upcoming:
                return viewModel.upcoming.count
            case .popular:
                return viewModel.popular.count
            case .topRated:
                return viewModel.topRated.count
            case .popularTVShows:
                return viewModel.popularTVShows.count
            case .topRatedTVShows:
                return viewModel.topRatedTVShows.count
            case .thisWeek:
                return viewModel.thisWeekTVShows.count
            case .newEpisodes:
                return viewModel.newEpisodes.count
            case .none:
                return 0
            }
        case 1:
            return viewModel.sortedMovies.values.count
        case 2:
            return viewModel.sortedTVShow.values.count
        default:
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let bigCell = collectionView.dequeueReusableCell(withReuseIdentifier: BigMediaCell.identifier,
                                                               for: indexPath) as? BigMediaCell else {
            return UICollectionViewCell()
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCell.identifier,
                                                            for: indexPath) as? MediaCell else {
            return UICollectionViewCell()
        }
        bigCell.delegate = self
        bigCell.viewController = self
        cell.delegate = self
        cell.viewController = self
        let section = MovieSectionNumber(rawValue: indexPath.section)
        switch customSegmentedControl.selectedIndex {
        case 0:
            switch section {
            case .onGoing:
                let movie = viewModel.onGoind[indexPath.item]
                bigCell.bindWithMedia(media: movie)
                return bigCell
            case .upcoming:
                let movie = viewModel.upcoming[indexPath.item]
                cell.bindWithMedia(media: movie)
                return cell
            case .popular:
                let movie = viewModel.popular[indexPath.item]
                cell.bindWithMedia(media: movie)
                return cell
            case .topRated:
                let movie = viewModel.topRated[indexPath.item]
                cell.bindWithMedia(media: movie)
                return cell
            case .popularTVShows:
                let tvShow = viewModel.popularTVShows[indexPath.item]
                bigCell.bindWithMedia(media: tvShow)
                return bigCell
            case .topRatedTVShows:
                let tvShow = viewModel.topRatedTVShows[indexPath.item]
                cell.bindWithMedia(media: tvShow)
                return cell
            case .thisWeek:
                let tvShow = viewModel.thisWeekTVShows[indexPath.item]
                cell.bindWithMedia(media: tvShow)
                return cell
            case .newEpisodes:
                let tvShow = viewModel.newEpisodes[indexPath.item]
                cell.bindWithMedia(media: tvShow)
                return cell
            case .none:
                return cell
            }
        case 1:
            let genre = viewModel.sortedMovies.keys.sorted(by: <)[indexPath.section]
            let movie = viewModel.sortedMovies[genre]![indexPath.item]
            cell.bindWithMedia(media: movie)
            return cell
        case 2:
            let genre = viewModel.sortedTVShow.keys.sorted(by: <)[indexPath.section]
            let tvShow = viewModel.sortedTVShow[genre]![indexPath.item]
            cell.bindWithMedia(media: tvShow)
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                                      withReuseIdentifier: DiscoverHeader.identifier,
                                                                                      for: indexPath) as? DiscoverHeader else {
                return UICollectionReusableView()
            }
            let section = MovieSectionNumber(rawValue: indexPath.section)
            switch customSegmentedControl.selectedIndex {
            case 0:
                switch section {
                case .onGoing:
                    sectionHeader.label.text = MovieSection.onGoing.rawValue
                    return sectionHeader
                case .upcoming:
                    sectionHeader.label.text = MovieSection.upcoming.rawValue
                    return sectionHeader
                case .popular:
                    sectionHeader.label.text = MovieSection.popular.rawValue
                    return sectionHeader
                case .topRated:
                    sectionHeader.label.text = MovieSection.topRated.rawValue
                    return sectionHeader
                case .popularTVShows:
                    sectionHeader.label.text = MovieSection.popularTVShows.rawValue
                    return sectionHeader
                case .topRatedTVShows:
                    sectionHeader.label.text = MovieSection.topRatedTVShows.rawValue
                    return sectionHeader
                case .thisWeek:
                    sectionHeader.label.text = MovieSection.thisWeek.rawValue
                    return sectionHeader
                case .newEpisodes:
                    sectionHeader.label.text = MovieSection.newEpisodes.rawValue
                    return sectionHeader
                case .none:
                    return sectionHeader
                }
            case 1:
                sectionHeader.label.text = viewModel.sortedMovies.keys.sorted(by: <)[indexPath.section]
                return sectionHeader
            case 2:
                sectionHeader.label.text = viewModel.sortedTVShow.keys.sorted(by: <)[indexPath.section]
                return sectionHeader
            default:
                return UICollectionReusableView()
            }
        } else {
            return UICollectionReusableView()
        }
    }
}
// MARK: - Push Detatil VC
extension DiscoverViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = MovieSectionNumber(rawValue: indexPath.section)
        let detailVC = MovieDetailViewController()
        switch customSegmentedControl.selectedIndex {
        case 0:
            switch section {
            case .onGoing:
                detailVC.movieId = viewModel.onGoind[indexPath.item].id!
            case .upcoming:
                detailVC.movieId = viewModel.upcoming[indexPath.item].id!
            case .popular:
                detailVC.movieId = viewModel.popular[indexPath.item].id!
            case .topRated:
                detailVC.movieId = viewModel.topRated[indexPath.item].id!
            case .popularTVShows:
                detailVC.tvShowId = viewModel.popularTVShows[indexPath.item].id!
            case .topRatedTVShows:
                detailVC.tvShowId = viewModel.topRatedTVShows[indexPath.item].id!
            case .thisWeek:
                detailVC.tvShowId = viewModel.thisWeekTVShows[indexPath.item].id!
            case .newEpisodes:
                detailVC.tvShowId = viewModel.newEpisodes[indexPath.item].id!
            case .none:
                print("Error")
            }
        case 1:
            let genre = viewModel.sortedMovies.keys.sorted(by: <)[indexPath.section]
            let movie = viewModel.sortedMovies[genre]![indexPath.item]
            detailVC.movieId = movie.id!
        case 2:
            let genre = viewModel.sortedTVShow.keys.sorted(by: <)[indexPath.section]
            let tvShow = viewModel.sortedTVShow[genre]![indexPath.item]
            detailVC.tvShowId = tvShow.id!
        default:
            print("Error")
        }
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension DiscoverViewController: ViewModelProtocol {
    func updateView() {
        self.colletionView.reloadData()
    }
}

extension DiscoverViewController: CustomSegmentedControlDelegate {
    func change(to index: Int) {
        self.colletionView.reloadData()
    }
}
