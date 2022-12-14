//
//  SearchViewController.swift
//  CloudMovies
//
//  Created by Артем Билый on 03.10.2022.
//
import UIKit

final class SearchViewController: UIViewController {
    // MARK: - Init UI
    private let searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.searchBar.placeholder = "Filter by title text"
        return search
    }()
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tableFooterView = UIView() // hide extra separator
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()
    private let scrollUpButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        let image = UIImage(named: "downarrow")
        button.setImage(image, for: .normal)
        return button
    }()
    private let noRecentLabel: UILabel = {
        let noRecentLabel = UILabel()
        noRecentLabel.text = "No Recent Search"
        noRecentLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        noRecentLabel.textAlignment = NSTextAlignment.center
        return noRecentLabel
    }()
    private let clearAll: UIButton = {
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.setTitleColor(.systemRed, for: .normal)
        return clearButton
    }()
    private let customSegmentedControl: CustomSegmentedControl = {
        let control = CustomSegmentedControl()
        control.setButtonTitles(buttonTitles: ["Movies", "TV Shows"])
        control.backgroundColor = .clear
        return control
    }()
    private let headerView = UIView()
    private let loaderView = UIActivityIndicatorView()
    private lazy var refreshControl = UIRefreshControl()
    lazy var viewModel = SearchViewModel(delegate: self)
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate()
        setup()
        setupDismissKeyboardGesture()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSavedList()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func viewWillLayoutSubviews() {
        layout()
    }
    // MARK: - Delegate setup
    private func delegate() {
        tableView.register(SearchCell.self, forCellReuseIdentifier: SearchCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "recentlyCell")
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.searchTextField.delegate = self
        searchController.searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        searchController.searchBar.searchTextField.delegate = self
        viewModel.delegate = self
    }
    // MARK: - SetupUI
    private func setup() {
        navigationItem.searchController = searchController
        definesPresentationContext = true
        scrollUpButton.addTarget(self, action: #selector(scrollUp), for: .touchUpInside)
        searchController.searchBar.keyboardType = .asciiCapable
        searchController.searchBar.returnKeyType = .search
        searchController.searchBar.autocapitalizationType = .sentences
        searchController.hidesNavigationBarDuringPresentation = false
        refreshControl.tintColor = UIColor.systemRed
        refreshControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        refreshControl.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        loaderView.color = .systemRed
        noRecentLabel.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height)
        clearAll.addTarget(self, action: #selector(resetResults), for: .touchUpInside)
        customSegmentedControl.delegate = self
        view.addSubview(tableView)
        tableView.addSubview(refreshControl)
        view.addSubview(loaderView)
        view.addSubview(scrollUpButton)
    }
    // MARK: - Constraints
    private func layout() {
        tableView.frame = view.bounds
        scrollUpButton.translatesAutoresizingMaskIntoConstraints = false
        loaderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollUpButton.widthAnchor.constraint(equalToConstant: 40),
            scrollUpButton.heightAnchor.constraint(equalToConstant: 40),
            scrollUpButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(view.frame.height * 0.15)),
            scrollUpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                     constant: -(view.frame.width * 0.05)),
            loaderView.widthAnchor.constraint(equalToConstant: 50),
            loaderView.heightAnchor.constraint(equalToConstant: 50),
            loaderView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(view.frame.height * 0.15)),
            loaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(view.frame.width * 0.05))
        ])
    }
    // MARK: - Download new list
    private func updateSavedList() {
        loaderView.isHidden = true
        scrollUpButton.isHidden = true
        CheckInWatchList.shared.getMoviesID {
            self.tableView.reloadData()
        }
        CheckInWatchList.shared.getTVShowsID {
            self.tableView.reloadData()
        }
    }
    // MARK: - Update by refresh controller
    // makes 20 results
    @objc private func pullToRefresh(_ sender: UIButton) {
        switch searchController.isActive {
        case true:
            self.refreshControl.isHidden = false
            guard let query = searchController.searchBar.text,
                  !query.trimmingCharacters(in: .whitespaces).isEmpty else {
                hideLoading()
                viewModel.reload()
                return
            }
            let queryAllowedUrl = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            viewModel.currentPage = 0
            switch customSegmentedControl.selectedIndex {
            case 0:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.viewModel.reload()
                    self?.viewModel.getSearchResultsMovies(queryString: queryAllowedUrl ?? "")
                    self?.refreshControl.endRefreshing()
                }
            case 1:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.viewModel.reload()
                    self?.viewModel.getSearchResultsTV(queryString: queryAllowedUrl ?? "")
                    self?.refreshControl.endRefreshing()
                }
            default:
                return
            }
        case false:
            self.refreshControl.endRefreshing()
        }
    }
    @objc private func scrollUp() {
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    private func setupDismissKeyboardGesture() {
        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.addGestureRecognizer(dismissKeyboardTap)
    }
    // dismiss keyboard by tap
    @objc func viewTapped(_ recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
        searchController.searchBar.endEditing(true)
        recognizer.cancelsTouchesInView = false
    }
    @objc func resetResults() {
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.viewModel.recentlySearchContainer.removeAll()
            self?.viewModel.recentlySearch.removeAll()
            self?.updateView()
            self?.hideLoading()
        }
    }
}
// MARK: - SearchController Delegate
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            hideLoading()
            viewModel.reload()
            return
        }
        let queryAllowedUrl = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        viewModel.reload()
        viewModel.currentPage = 0
        switch customSegmentedControl.selectedIndex {
        case 0:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.viewModel.reload()
                self?.viewModel.getSearchResultsMovies(queryString: queryAllowedUrl ?? "")
            }
        case 1:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.viewModel.reload()
                self?.viewModel.getSearchResultsTV(queryString: queryAllowedUrl ?? "")
            }
        default:
            return
        }
    }
}
// MARK: - SearchBar Delegate
extension SearchViewController: UISearchBarDelegate {
    // MARK: textfield Cancel Button
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.reload()
        self.scrollUpButton.isHidden = true // doesnt work
        searchBar.text = ""
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchController.searchBar.text,
              !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let queryAllowedUrl = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        searchBar.resignFirstResponder()
        viewModel.configureRecentlySearchContainer(title: queryAllowedUrl ?? "")
    }
}
// MARK: - TextField Delegate
extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
// MARK: - TableView DataSource
extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch searchController.isActive {
        case true:
            return UIView()
        case false:
            headerView.frame =  CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.frame.height / 2)
            customSegmentedControl.frame = CGRect(x: tableView.frame.minX,
                                                  y: 7,
                                                  width: tableView.frame.width,
                                                  height: 40)
            headerView.addSubview(customSegmentedControl)
            return headerView
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        50
    }
    // MARK: cell numbers in row
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch searchController.isActive {
        case true:
            self.noRecentLabel.isHidden = true
            self.scrollUpButton.isHidden = false
            return viewModel.media.count
        case false:
            if viewModel.recentlySearch.count == 0 {
                self.clearAll.isHidden = true
                self.tableView.backgroundView = noRecentLabel
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.noRecentLabel.isHidden = false
                }
            } else {
                self.clearAll.isHidden = false
                self.noRecentLabel.isHidden = true
            }
            return viewModel.recentlySearch.count
        }
    }
    // MARK: cell configure
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch searchController.isActive {
        case true:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchCell.identifier,
                                                           for: indexPath) as? SearchCell
            else { return UITableViewCell() }
            let movie = viewModel.media[indexPath.row]
            cell.bindWithViewMedia(media: movie)
            cell.delegate = self
            cell.viewController = self
            return cell
        case false:
            let recentlySearchCell = tableView.dequeueReusableCell(withIdentifier: "recentlyCell", for: indexPath)
            recentlySearchCell.textLabel?.text = viewModel.recentlySearch[indexPath.row]
            return recentlySearchCell
        }
    }
    // MARK: selected cell -> detailVC
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        searchController.searchBar.searchTextField.endEditing(true)
        switch searchController.isActive {
        case true:
            let detailVC = MovieDetailViewController()
            detailVC.movieId = viewModel.media[indexPath.row].id!
            self.navigationController?.pushViewController(detailVC, animated: true)
        case false:
            viewModel.reload()
            viewModel.currentPage = 0
            let query = self.viewModel.recentlySearch[indexPath.row]
            let queryAllowedUrl = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            self.searchController.searchBar.text = query
            self.showLoading()
            switch customSegmentedControl.selectedIndex {
            case 0:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.viewModel.reload()
                    self?.viewModel.getSearchResultsMovies(queryString: queryAllowedUrl ?? "")
                    self?.searchController.isActive = true
                }
            case 1:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.viewModel.reload()
                    self?.viewModel.getSearchResultsTV(queryString: queryAllowedUrl ?? "")
                    self?.searchController.isActive = true
                }
            default:
                return
            }
        }
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let query = searchController.searchBar.text, !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        let queryAllowedUrl = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        switch searchController.isActive {
        case true:
            if (viewModel.currentPage <= viewModel.totalPages) && (indexPath.row == viewModel.media.count - 1) {
                self.showLoading()
                switch self.customSegmentedControl.selectedIndex {
                case 0:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.viewModel.getSearchResultsMovies(queryString: queryAllowedUrl ?? "")
                    }
                case 1:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.viewModel.getSearchResultsTV(queryString: queryAllowedUrl ?? "")
                    }
                default:
                    return
                }
            }
        case false:
            return
        }
    }
}
// MARK: - TableView Delegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch searchController.isActive {
        case true:
            return 200.0
        case false:
            return 40
        }
    }
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch searchController.isActive {
        case true:
            return UISwipeActionsConfiguration()
        case false:
            let deleteButton = UIContextualAction(style: .normal, title: "Delete") { _, _, _ in
                tableView.beginUpdates()
                self.viewModel.recentlySearch.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.endUpdates()
            }
            deleteButton.backgroundColor = .systemRed
            let configuration = UISwipeActionsConfiguration(actions: [deleteButton])
            configuration.performsFirstActionWithFullSwipe = false
            return configuration
        }
    }
}
// MARK: - ViewModelProtocol UI Updates
extension SearchViewController: ViewModelProtocol {
    func showLoading() {
        scrollUpButton.isHidden = true
        loaderView.isHidden = false
        loaderView.startAnimating()
        view.bringSubviewToFront(loaderView)
    }
    func hideLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.loaderView.stopAnimating()
            self?.loaderView.isHidden = true
        }
    }
    func updateView() {
        if viewModel.media.count == 0 {
            self.scrollUpButton.isHidden = true
        } else {
            self.scrollUpButton.isHidden = false
        }
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
}
// MARK: - Delegate Custom Segmented
extension SearchViewController: CustomSegmentedControlDelegate {
    func change(to index: Int) {
        self.tableView.reloadData()
    }
}
