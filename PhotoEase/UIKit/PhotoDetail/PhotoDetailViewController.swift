//
//  PhotoDetailViewController.swift
//  PhotoEase
//
//  Created by Son on 28/02/2025.
//

import Foundation
import UIKit
import Combine
import Kingfisher

class PhotoDetailViewController: UIViewController {
    
    // UI variables
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!
    
    // Other variables
    private var photo: Photo!
    private var viewModel: PhotoDetailViewModel!
    private var cancellables: Set<AnyCancellable> = []
    private var photoIsDownloadedOnce = false
    var photoUpdatedCallback: ((Photo) -> ())?
    
    convenience init(photo: Photo) {
        self.init(nibName: "PhotoDetailViewController", bundle: nil)
        self.photo = photo
        self.viewModel = PhotoDetailViewModel(photo: photo)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupNavigationController()
        self.setupScrollView()
        self.setupPhotoImageView()
        self.setupTitleLabel()
        self.setupLoadingIndicatorView()
        self.setupDataBinding()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Call funtion loadPhoto() here to ensure the UI is ready, avoiding layout issues (especially since the image size might be small)
        // The variable photoIsDownloadedOnce is used to prevent potential multiple loads
        if !self.photoIsDownloadedOnce {
            self.viewModel.loadPhoto()
            self.photoIsDownloadedOnce = true
        }
    }
    
    // MARK: - Setup UI components
    private func setupNavigationController() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.title = NSLocalizedString("Photo Detail", comment: "Title of the Photo Detail screen")
        
        // Setup right navigation bar button
        self.navigationItem.rightBarButtonItem = self.getRightBarButtonItem()
    }
    
    private func getRightBarButtonItem() -> UIBarButtonItem {
        let iconName = PhotoDataHelper.shared.isFavoritePhoto(photoId: self.photo.id) ? "star.fill" : "star"
        let buttonItem = UIBarButtonItem(image: UIImage(systemName: iconName), style: .plain, target: self, action: #selector(toggleFavoriteStatus))
        return buttonItem
    }
    
    private func setupScrollView() {
        self.scrollView.frame = UIScreen.main.bounds
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 3.0
        self.scrollView.zoomScale = 1.0
        self.scrollView.alwaysBounceVertical = false
        self.scrollView.alwaysBounceHorizontal = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.delegate = self
        
        // Add double tap gesture recognizer to the scroll view
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        self.scrollView.addGestureRecognizer(doubleTapRecognizer)
    }
    
    private func setupPhotoImageView() {
        self.photoImageView.frame = CGRect(origin: self.scrollView.center, size: CGSize(width: 50, height: 50))
        self.photoImageView.image = nil
        self.photoImageView.contentMode = .scaleAspectFit
    }
    
    private func setupTitleLabel() {
        if let labelContainerView = self.titleLabel.superview {
            labelContainerView.backgroundColor = UIColor.gray.withAlphaComponent(0.75)
            labelContainerView.layer.cornerRadius = 10
            labelContainerView.layer.borderColor = UIColor.clear.cgColor
            self.view.bringSubviewToFront(labelContainerView)
        }
        self.titleLabel.text = self.photo.title
    }
    
    private func setupLoadingIndicatorView() {
        self.loadingIndicatorView.hidesWhenStopped = true
        self.loadingIndicatorView.startAnimating()
    }
    
    private func setupDataBinding() {
        
        // Handle the downloaded image
        self.viewModel.$image
        .receive(on: DispatchQueue.main)
        .sink { [weak self] downloadedImage in
            guard let self = self else { return }
            guard let image = downloadedImage else { return }
            
            self.adjustFrameForScrollView(imageWidth: self.photoImageView.frame.width)
            self.scrollView.isScrollEnabled = false
            self.photoImageView.alpha = 0.0
            
            // Display image with animation
            UIView.animate(withDuration: 0.75) {
                self.adjustFrameForImageView(image: image)
                self.movePhotoToCenter()
                self.photoImageView.alpha = 1.0
            }
        }
        .store(in: &cancellables)
        
        // Handle the loading status
        self.viewModel.$isLoading
        .receive(on: DispatchQueue.main)
        .dropFirst() // Ignore the initial value (false)
        .removeDuplicates()
        .sink { [weak self] isLoading in
            guard let self = self else { return }
            
            if isLoading {
                self.loadingIndicatorView.startAnimating()
            } else {
                self.loadingIndicatorView.stopAnimating()
            }
        }
        .store(in: &cancellables)
        
        // Handle favorite status change
        self.viewModel.favoriteStatusChanged
        .receive(on: DispatchQueue.main)
        .sink { [weak self] updatedPhoto in
            guard let self = self else { return }
            // Update navigationbar item
            self.navigationItem.rightBarButtonItem = self.getRightBarButtonItem()
            // Notify change
            self.photoUpdatedCallback?(updatedPhoto)
        }
        .store(in: &cancellables)
        
        // Handle the error message
        self.viewModel.$errorMessage
        .receive(on: DispatchQueue.main)
        .sink { [weak self] message in
            guard let self = self else { return }
            guard let aMessage = message, !aMessage.isEmpty else { return }
            
            AlertHelper.showErrorMessage(from: self, message: aMessage, closeAction: nil)
        }
        .store(in: &cancellables)
    }
}

// MARK: - UIScrollView Delegate
extension PhotoDetailViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.photoImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        // Check if scrollView is zoomed out to its minimum scale
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            
            // Adjust the scrollView's frame to match the current width of the photoImageView,
            self.adjustFrameForScrollView(imageWidth: self.photoImageView.frame.width)
            
            // Disable scrolling when zoomed out to minimum scale to prevent unwanted actions
            scrollView.isScrollEnabled = false
        }
        
        self.movePhotoToCenter()
    }
}

// MARK: - Actions
extension PhotoDetailViewController {
    
    @objc private func toggleFavoriteStatus() {
        if PhotoDataHelper.shared.isFavoritePhoto(photoId: self.photo.id) {
            AlertHelper.showConfirmation(from: self, message: NSLocalizedString("Are you sure to dislike this photo?", comment: "The content of confirm popup to dislike a photo"), confirmActionTitle: NSLocalizedString("Action-Title-Confirm", comment: "Title of confirm action"), cancelActionTitle: NSLocalizedString("Action-Title-Cancel", comment: "Title of cancel action")) { [weak self] in
                guard let self = self else { return }
                self.viewModel.toggleFavoriteStaus(of: self.photo, isMarkedAsFavorite: false)
            }
        } else {
            debugPrint("Mark favorite photo with id = \(self.photo.id)")
            self.viewModel.toggleFavoriteStaus(of: self.photo, isMarkedAsFavorite: true)
        }
    }
    
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        if self.scrollView.zoomScale > self.scrollView.minimumZoomScale {
            self.scrollView.setZoomScale(self.scrollView.minimumZoomScale, animated: true)
        } else {
            // Make sure the scrollview is scrollable
            self.scrollView.isScrollEnabled = true
            
            // Zoom to the area that user taps
            let zoomScale = self.scrollView.maximumZoomScale
            let center = recognizer.location(in: recognizer.view)
            let zoomRect = self.zoomRectForScale(scale: zoomScale, center: center)
            self.scrollView.zoom(to: zoomRect, animated: true)
        }
    }
}

// MARK: - Helpers
extension PhotoDetailViewController {
    
    private func movePhotoToCenter() {
        // Adjusts the image's position to make sure it is in the center of the scrollView
        let boundsSize = self.scrollView.bounds.size
        var imageViewFrame = self.photoImageView.frame
        imageViewFrame.origin.x = (boundsSize.width > imageViewFrame.size.width) ? (boundsSize.width - imageViewFrame.size.width) / 2 : 0
        imageViewFrame.origin.y = (boundsSize.height > imageViewFrame.size.height) ? (boundsSize.height - imageViewFrame.size.height) / 2 : 0
        self.photoImageView.frame = imageViewFrame
    }
    
    private func adjustFrameForImageView(image: UIImage) {
        self.photoImageView.image = image
        
        // Calculate the size for the image
        // The width should not be greater than screen's width
        let ratio = image.size.width / image.size.height
        let imageWidth = min(self.view.bounds.width, image.size.width)
        let imageHeight = imageWidth / ratio
        self.photoImageView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: imageWidth, height: imageHeight))
    }
    
    private func adjustFrameForScrollView(imageWidth: CGFloat) {
        // Adjust the scrollView's frame and content size
        // Set the scrollView's frame to match the bounds of its containing view, to make sure it occupies the full area intended for displaying the image.
        var scrollViewFrame = self.scrollView.bounds
        scrollViewFrame.origin = .zero
        self.scrollView.bounds = scrollViewFrame
        self.scrollView.contentSize = CGSize(width: imageWidth, height: self.scrollView.frame.height)
    }
    
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        let bounds = self.scrollView.bounds
        
        zoomRect.size.width = bounds.size.width / scale
        zoomRect.size.height = bounds.size.height / scale
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
}
