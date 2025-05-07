//
//  PhotosListViewController.swift
//  PhotoEase
//
//  Created by Son on 27/02/2025.
//

import Foundation
import UIKit
import Combine

class PhotosListViewController: UIViewController {
    
    // UI variables
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!
    
    // Other variables
    private var viewModel = PhotoListViewModel()
    private var cancellables: Set<AnyCancellable> = []
    private let searchController = UISearchController(searchResultsController: nil)
    private let refreshControl = UIRefreshControl()
    private var isInitialViewLoadDone = false
    var photoUpdatedCallback: ((Photo) -> ())?
    
    convenience init(photoListType: PhotosListType) {
        self.init(nibName: "PhotosListViewController", bundle: nil)
        self.viewModel.photoListType = photoListType
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI components
        self.setupNavigationController()
        self.setupSearchController()
        self.setupTableView()
        self.setupLoadingIndicatorView()
        self.setupEmptyLabel()
        self.setupDataBinding()
        
        // Fetch photos
        self.viewModel.fetchPhotos(from: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Executed only during the first appearance
        if !self.isInitialViewLoadDone {
            self.isInitialViewLoadDone = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Executed when coming back to this view from another view controller
        if self.isInitialViewLoadDone {
            self.tableView.reloadData()
        }
    }
    
    private func setupNavigationController() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.title = self.viewModel.photoListType.displayTitleString
        
        // Right button
        self.navigationItem.rightBarButtonItem = self.createRightBarButtonItem(for: self.viewModel.photoListType)
    }
    
    // Function to create a bar button item with a specific type
    private func createRightBarButtonItem(for type: PhotosListType) -> UIBarButtonItem {
        let iconName = type == .all ? "star.fill" : "star"
        return UIBarButtonItem(image: UIImage(systemName: iconName), style: .plain, target: self, action: #selector(showPhotosList))
    }
    
    private func setupSearchController() {
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = NSLocalizedString("Search Photo", comment: "Placeholder of the searchbar")
        self.searchController.searchBar.autocorrectionType = .no
        self.searchController.searchBar.spellCheckingType = .no
        self.searchController.searchBar.smartQuotesType = .no
        self.definesPresentationContext = true
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupTableView() {
        // Add 'pull to refresh' action
        self.refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        self.refreshControl.tintColor = UIColor.lightGray
        self.tableView.refreshControl = self.refreshControl
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UINib(nibName: "PhotoTableViewCell", bundle: nil), forCellReuseIdentifier: "PhotoTableViewCell")
        self.tableView.register(UINib(nibName: "LoadMoreTableViewCell", bundle: nil), forCellReuseIdentifier: "LoadMoreTableViewCell")
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func setupLoadingIndicatorView() {
        self.loadingIndicatorView.hidesWhenStopped = true
        self.loadingIndicatorView.startAnimating()
    }
    
    private func setupEmptyLabel() {
        self.emptyLabel.text = NSLocalizedString("No Photos", comment: "The display text for empty state")
        self.emptyLabel.isHidden = true
    }
    
    private func setupDataBinding() {
        // Handle photos data
        self.viewModel.$filteredPhotos
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            guard let self = self else { return }
            self.tableView.reloadData()
            self.updateEmptyState()
        }
        .store(in: &self.cancellables)
        
        // Handle loading state
        self.viewModel.$loadingStatus
        .receive(on: DispatchQueue.main)
        .sink { [weak self] loadingStatus in
            guard let self = self else { return }

            // The center loading indicator is used only for initial loads, not for 'load more' & 'pull to refresh'
            if loadingStatus.isLoading && !loadingStatus.isLoadMore && !self.refreshControl.isRefreshing {
                self.loadingIndicatorView.startAnimating()
            } else {
                // Stop all loading animations when not loading or after loading
                self.refreshControl.endRefreshing()
                self.loadingIndicatorView.stopAnimating()
            }
            
            self.updateEmptyState()
        }
        .store(in: &cancellables)
        
        // Handle error message
        self.viewModel.$errorMessage
        .receive(on: DispatchQueue.main)
        .sink { [weak self] message in
            guard let self = self else { return }
            guard let aMessage = message, !aMessage.isEmpty else { return }
            AlertHelper.showErrorMessage(from: self, message: aMessage, closeAction: nil)
        }
        .store(in: &cancellables)
        
        // Handle favorite status change
        self.viewModel.favoriteStatusChanged
        .receive(on: DispatchQueue.main)
        .sink { [weak self] updatedPhoto in
            guard let self = self else { return }
            self.updateFavoriteChange(of: updatedPhoto)
            self.photoUpdatedCallback?(updatedPhoto)
        }
        .store(in: &cancellables)
    }
    
    private func updateEmptyState() {
        self.emptyLabel.isHidden = self.viewModel.filteredPhotos.count > 0 || self.viewModel.loadingStatus.isLoading
    }
    
    private func updateFavoriteChange(of updatedPhoto: Photo) {
        if self.viewModel.photoListType == .all { // For type all, just reload the cell
            // If the view is on-screen, just reload the updated cell
            if self.isViewLoaded && self.view.window != nil {
                if let index = self.viewModel.filteredPhotos.firstIndex(where: { photo in
                    photo.id == updatedPhoto.id
                }) {
                    let updatedIndexPath = IndexPath(row: index, section: 0)
                    self.tableView.reloadRows(at: [updatedIndexPath], with: .none)
                }
            }
        } else { // For type favorite, refresh the list
            self.viewModel.refresh(from: self)
        }
    }
    
    private func isInSearchMode() -> Bool {
        let searchBar = self.searchController.searchBar
        if let text = searchBar.searchTextField.text, !text.isEmpty {
            return true
        } else {
            return searchBar.searchTextField.isFirstResponder
        }
    }
    
    private func shouldShowLoadMoreCell() -> Bool {
        return !self.isInSearchMode() && self.viewModel.canLoadMore()
    }
}

// MARK: - Search Result Update
extension PhotosListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else { return }
        self.viewModel.searchPhotos(by: searchText)
    }
}

// MARK: - TableView
extension PhotosListViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Datasource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.filteredPhotos.count + (self.shouldShowLoadMoreCell() ? 1 : 0) // +1 is for loadmore cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < self.viewModel.filteredPhotos.count { // Photo cell
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoTableViewCell", for: indexPath) as? PhotoTableViewCell else {
                return UITableViewCell()
            }
            let photo = self.viewModel.filteredPhotos[indexPath.row]
            cell.config(with: photo)
            cell.delegate = self
            return cell
        } else { // Load more cell
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "LoadMoreTableViewCell", for: indexPath) as? LoadMoreTableViewCell else {
                return UITableViewCell()
            }
            cell.startLoading()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Check and trigger pagination if the last cell (load more cell) is about to be displayed
        guard indexPath.row == self.viewModel.filteredPhotos.count else { return }
        if self.shouldShowLoadMoreCell() {
            // I do a delay of 0.35 seconds (on purpose) to simulate the loading state, as the API responses are too fast to visibly notice it.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.viewModel.fetchPhotos(from: self, needRefresh: false, isLoadMore: true)
            }
        }
    }
    
    // MARK: - Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard self.viewModel.filteredPhotos.count > indexPath.row else { return }
        
        // To end selected state of the cell
        tableView.deselectRow(at: indexPath, animated: true)
        
        let photo = self.viewModel.filteredPhotos[indexPath.row]
        let photoDetailViewController = PhotoDetailViewController(photo: photo)
        photoDetailViewController.photoUpdatedCallback = { [weak self] updatedPhoto in
            guard let self = self else { return }
            self.updateFavoriteChange(of: updatedPhoto)
        }
        self.view.endEditing(true)
        self.navigationController?.pushViewController(photoDetailViewController, animated: true)
    }
}

// MARK: - Photo Cell Delegate
extension PhotosListViewController: PhotoTableViewCellDelegate {
    
    func didTapToToggleFavoriteStatus(from cell: PhotoTableViewCell) {
        // Show confirm popup if dislike the photo
        if PhotoDataHelper.shared.isFavoritePhoto(photoId: cell.photo.id) {
            AlertHelper.showConfirmation(from: self, message: NSLocalizedString("Are you sure to dislike this photo?", comment: "The content of confirm popup to dislike a photo"), confirmActionTitle: NSLocalizedString("Action-Title-Confirm", comment: "Title of confirm action"), cancelActionTitle: NSLocalizedString("Action-Title-Cancel", comment: "Title of cancel action")) { [weak self] in
                guard let self = self else { return }
                self.viewModel.toggleFavoriteStaus(of: cell.photo, isMarkedAsFavorite: false, from: self)
            }
        } else {
            debugPrint("Mark favorite photo with id = \(cell.photo.id)")
            self.viewModel.toggleFavoriteStaus(of: cell.photo, isMarkedAsFavorite: true, from: self)
        }
    }
}

// MARK: - Actions
extension PhotosListViewController {
    
    @objc private func showPhotosList() {
        guard let navigationController = self.navigationController else { return }
        
        // Prevent pushing duplicated screens to stack
        if navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            let photosListViewController = PhotosListViewController(photoListType: (self.viewModel.photoListType == .all ? .favorite : .all))
            photosListViewController.photoUpdatedCallback = { [weak self] updatedPhoto in
                guard let self = self else { return }
                self.updateFavoriteChange(of: updatedPhoto)
            }
            navigationController.pushViewController(photosListViewController, animated: true)
        }
    }
    
    @objc private func refreshData(_ sender: UIRefreshControl) {
        self.viewModel.refresh(from: self)
    }
}
