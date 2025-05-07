//
//  PhotoViewModel.swift
//  PhotoEase
//
//  Created by Son on 27/02/2025.
//

import Foundation
import Combine
import UIKit

// Enum for photo list type
enum PhotosListType: Int {
    case all
    case favorite
}

extension PhotosListType {
    var displayTitleString: String {
        switch self {
        case .all:
            return NSLocalizedString("Photo List", comment: "Title of the Photo List screen")
        case .favorite:
            return NSLocalizedString("Photo List (Favorite)", comment: "Title of the Photo List (Favorite) screen")
        }
    }
}

// Defines the loading state, including whether data is loading and if the current load is from pagination loads
typealias PhotoListLoading = (isLoading: Bool, isLoadMore: Bool)

class PhotoListViewModel: ObservableObject {
    
    // Type of the photo list
    var photoListType: PhotosListType = .all

    // List of photos fetched from the server
    @Published var photos: [Photo] = []
    
    // List of photos that matches the search query
    @Published var filteredPhotos: [Photo] = []
    
    // Variable to indicate loading state
    @Published var loadingStatus: PhotoListLoading = (false, false)
    
    // Error message when loading fails
    @Published var errorMessage: String?
    
    // Variables for pagination
    var numberOfPhotosPerRequest: Int = 25
    var currentPage: Int = 0
    var lastLoadCount: Int = -1
    
    // Variable to manage the favorite status of a photo
    var favoriteStatusChanged = PassthroughSubject<Photo, Never>()
    
    // Set to store ongoing requests
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Fetch photos
    func fetchPhotos(from viewController: UIViewController, needRefresh: Bool = false, isLoadMore: Bool = false) {
        switch self.photoListType {
        case .all:
            guard !self.loadingStatus.isLoading, self.currentPage >= 0 else { return }
            
            if isLoadMore {
                self.currentPage += 1
            }
            let offset = self.currentPage * self.numberOfPhotosPerRequest
            debugPrint("Load \(self.numberOfPhotosPerRequest) photos from offset \(offset)")
            
            // Fetch photos from jsonplaceholder
            let urlString = "https://jsonplaceholder.typicode.com/photos?_start=\(self.currentPage * self.numberOfPhotosPerRequest)&_limit=\(self.numberOfPhotosPerRequest)"
            guard let requestURL = URL(string: urlString) else {
                fatalError("Given URL is invalid")
            }
            
            self.loadingStatus = PhotoListLoading(isLoading: true, isLoadMore: isLoadMore)
            
            URLSession.shared.dataTaskPublisher(for: requestURL)
            .map(\.data)
            .tryMap { data in
                if let json = String(data: data, encoding: .utf8) {
                    print("Response: \(json)")
                }
                return data
            }
            .decode(type: [Photo].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                self.loadingStatus = PhotoListLoading(isLoading: false, isLoadMore: isLoadMore)
                switch completion {
                case .failure(let error):
                    debugPrint("Error: \(error)")
                    if isLoadMore {
                        self.currentPage -= 1
                    }
                    self.lastLoadCount = -1
                    self.errorMessage = error.localizedDescription
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] photos in
                guard let self = self else { return }
                
                var currentPhotos = self.photos
                if needRefresh {
                    currentPhotos.removeAll()
                }
                currentPhotos.append(contentsOf: photos)
                self.lastLoadCount = photos.count
                
                self.photos = currentPhotos.sorted { $0.id < $1.id }
                self.filteredPhotos = self.photos
            })
            .store(in: &cancellables)
        
        case .favorite:
            // Fetch photos from CoreData
            // No pagination for this type
            self.loadingStatus = PhotoListLoading(isLoading: true, isLoadMore: false)
            self.photos = PhotoDataHelper.shared.getAllManagedPhotos().compactMap({ Photo.init(fromManagedPhoto: $0)}).sorted { $0.id < $1.id }
            self.filteredPhotos = self.photos
            self.loadingStatus = PhotoListLoading(isLoading: false, isLoadMore: false)
        }
    }
    
    func refresh(from viewController: UIViewController) {
        self.resetPaging()
        self.fetchPhotos(from: viewController, needRefresh: true, isLoadMore: false)
    }
    
    // MARK: - Pagination
    private func resetPaging() {
        self.currentPage = 0
        self.lastLoadCount = -1
    }
    
    func canLoadMore() -> Bool {
        guard self.photoListType == .all else { return false } // No load more for Favorite
        guard !self.loadingStatus.isLoading else { return false } // No load more if api is being called
        
        return self.photos.count > 0 && (self.lastLoadCount == -1 || self.lastLoadCount >= self.numberOfPhotosPerRequest)
    }
}

// MARK: - Helpers
extension PhotoListViewModel {
    
    // Function to handle the search by photo title
    func searchPhotos(by title: String) {
        guard !title.isEmpty else {
            self.filteredPhotos = self.photos // Clear the search result if there's no search text
            return
        }
        self.filteredPhotos = self.photos.filter({ $0.title.localizedCaseInsensitiveContains(title) })
    }
    
    // Function to handle the favorite status change
    func toggleFavoriteStaus(of photo: Photo, isMarkedAsFavorite: Bool, from viewController: UIViewController) {
        if isMarkedAsFavorite {
            PhotoDataHelper.shared.createNewManagedPhoto(from: photo)
        } else {
            PhotoDataHelper.shared.deleteManagedPhoto(byId: photo.id)
        }
        
        // Notify the change
        self.favoriteStatusChanged.send(photo)
        
        if self.photoListType == .favorite {
            self.refresh(from: viewController)
        }
    }
}
