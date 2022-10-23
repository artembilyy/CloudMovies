//
//  GenreListController.swift
//  CloudMovies
//
//  Created by Артем Билый on 03.10.2022.
//

import UIKit

final class MovieListViewController: UIViewController {
    
    private var movieListViewModel: MovieListViewModel
    
    init(movieListViewModel: MovieListViewModel) {
        self.movieListViewModel = movieListViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var blur: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var colletionView: UICollectionView = {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        return collectionView
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["Discover", "Movies", "TVShows"])
        let titleTextAttributeNormal = [NSAttributedString.Key.foregroundColor: UIColor.white]
        segmentedControl.setTitleTextAttributes(titleTextAttributeNormal, for: .normal)
        let titleTextAttributeSelected = [NSAttributedString.Key.foregroundColor: UIColor.black]
        segmentedControl.setTitleTextAttributes(titleTextAttributeSelected, for: .selected)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlPressed), for: .allEvents)
        return segmentedControl
    }()
    
    @objc func segmentedControlPressed() {
        colletionView.reloadData()
    }
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        //        presentAuthorizationVC()
        delegate()
        loadMovies()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        setupLayout()
    }
    
    private func presentAuthorizationVC() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let authorizationVC = AuthorizationViewController()
            authorizationVC.modalPresentationStyle = .fullScreen
            self.present(authorizationVC, animated: true)
        }
    }
    
    private func delegate() {
        colletionView.delegate = self
        colletionView.dataSource = self
        colletionView.register(MovieCell.self, forCellWithReuseIdentifier: MovieCell.cellIdentifier)
        colletionView.register(HeaderMovieSection.self, forSupplementaryViewOfKind:  UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderMovieSection.headerIdentifier)
    }
    
    private func setupUI() {
        navigationItem.title = "Cloud Movies"
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        colletionView.translatesAutoresizingMaskIntoConstraints = false
        colletionView.backgroundColor = .black
        view.addSubview(segmentedControl)
        view.addSubview(colletionView)
        view.addSubview(blur)
        colletionView.showsVerticalScrollIndicator = true
    }
    
    private func loadMovies() {
        movieListViewModel.getDiscoverScreen {
            DispatchQueue.main.async {
                self.colletionView.reloadData()
            }
        }
        
        movieListViewModel.sortedMovies {
            DispatchQueue.main.async {
                self.colletionView.reloadData()
            }
        }
        movieListViewModel.sortedTVShows {
            DispatchQueue.main.async {
                self.colletionView.reloadData()
            }
        }
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            colletionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            colletionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            colletionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            colletionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.heightAnchor.constraint(equalTo: tabBarController!.tabBar.heightAnchor, multiplier: 1)
        ])
    }
}

//TEST
public enum MovieSection: String, CaseIterable {
    case onGoing = "Now Playing Movies"
    case popular = "Popular Movies"
    case upcoming = "Upcoming Movies"
    case topRated = "Top Rated Movies"
}

public enum MovieSectionNumber: Int {
    case onGoing
    case popular
    case upcoming
    case topRated
}

let moviesSection = MovieSection.popular
//MARK: - DataSource
extension MovieListViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return MovieSection.allCases.count
        case 1:
            return movieListViewModel.sortedMovies.keys.count
        case 2:
            return movieListViewModel.sortedTVShow.keys.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = MovieSectionNumber(rawValue: section)
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            switch section {
            case .onGoing:
                return movieListViewModel.onGoind.count
            case .popular:
                return movieListViewModel.popular.count
            case .upcoming:
                return movieListViewModel.upcoming.count
            case .topRated:
                return movieListViewModel.topRated.count
                
            case .none:
                return 0
            }
        case 1:
            return movieListViewModel.sortedMovies.values.count
        case 2:
            return movieListViewModel.sortedTVShow.values.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCell.cellIdentifier, for: indexPath) as? MovieCell else {
            return UICollectionViewCell()
        }
        let section = MovieSectionNumber(rawValue: indexPath.section)
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            switch section {
            case .onGoing:
                let movie = movieListViewModel.onGoind[indexPath.item]
                cell.bindWithViewMovie(movie: movie)
                return cell
            case .popular:
                let movie = movieListViewModel.popular[indexPath.item]
                cell.bindWithViewMovie(movie: movie)
                return cell
            case .upcoming:
                let movie = movieListViewModel.upcoming[indexPath.item]
                cell.bindWithViewMovie(movie: movie)
                return cell
            case .topRated:
                let movie = movieListViewModel.topRated[indexPath.item]
                cell.bindWithViewMovie(movie: movie)
                return cell
            case .none:
                return cell
            }
        case 1:
            let genre = movieListViewModel.sortedMovies.keys.sorted(by: <)[indexPath.section]
            let movie = movieListViewModel.sortedMovies[genre]![indexPath.item]
            cell.bindWithViewMovie(movie: movie)
            return cell
        case 2:
            let genre = movieListViewModel.sortedTVShow.keys.sorted(by: <)[indexPath.section]
            let tvShow = movieListViewModel.sortedTVShow[genre]![indexPath.item]
            cell.bindWithViewTVShow(tvShow: tvShow)
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderMovieSection.headerIdentifier, for: indexPath) as? HeaderMovieSection else {
                return UICollectionReusableView()
            }
            let section = MovieSectionNumber(rawValue: indexPath.section)
            switch segmentedControl.selectedSegmentIndex {
            case 0:
                switch section {
                case .onGoing:
                    sectionHeader.label.text = MovieSection.onGoing.rawValue
                    return sectionHeader
                case .popular:
                    sectionHeader.label.text = MovieSection.popular.rawValue
                    return sectionHeader
                case .topRated:
                    sectionHeader.label.text = MovieSection.topRated.rawValue
                    return sectionHeader
                case .upcoming:
                    sectionHeader.label.text = MovieSection.upcoming.rawValue
                    return sectionHeader
                case .none:
                    return sectionHeader
                }
            case 1:
                sectionHeader.label.text = movieListViewModel.sortedMovies.keys.sorted(by: <)[indexPath.section]
                return sectionHeader
            case 2:
                sectionHeader.label.text = movieListViewModel.sortedTVShow.keys.sorted(by: <)[indexPath.section]
                return sectionHeader
            default:
                return UICollectionReusableView()
            }
        } else {
            return UICollectionReusableView()
        }
    }
}
//MARK: - Delegate
extension MovieListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let secondViewController = MovieDetailViewController()
        navigationController?.pushViewController(secondViewController, animated: true)
    }
}

