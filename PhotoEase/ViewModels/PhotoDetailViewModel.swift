//
//  PhotoDetailViewModel.swift
//  PhotoEase
//
//  Created by Son on 28/02/2025.
//

import Foundation
import Combine
import Kingfisher

class PhotoDetailViewModel: ObservableObject {
    
    // The photo to be handled by this view model
    @Published var photo: Photo!
    
    // The image data of the photo
    @Published var image: UIImage?
    
    // Variable to indicate loading state
    @Published var isLoading: Bool = false
    
    // Error message when loading fails
    @Published var errorMessage: String?
    
    // Variable to manage the favorite status of a photo
    var favoriteStatusChanged = PassthroughSubject<Photo, Never>()
    
    // Set to store ongoing requests
    var cancellables: Set<AnyCancellable> = Set()

    init(photo: Photo) {
        self.photo = photo
    }
    
    // Function to retrieve the original photo
    func loadPhoto() {
        guard let photoUrl = self.photo.url else { return }
        self.isLoading = true
        KingfisherManager.shared.retrieveImage(with: photoUrl) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let value):
                self.image = value.image
            case .failure(let error):
                debugPrint("Error loading image: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // Function to handle the favorite status change
    func toggleFavoriteStaus(of photo: Photo, isMarkedAsFavorite: Bool) {
        if isMarkedAsFavorite {
            PhotoDataHelper.shared.createNewManagedPhoto(from: photo)
        } else {
            PhotoDataHelper.shared.deleteManagedPhoto(byId: photo.id)
        }
        
        // Notify the change
        self.favoriteStatusChanged.send(photo)
    }
}
