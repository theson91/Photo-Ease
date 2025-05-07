//
//  PhotoTableViewCell.swift
//  PhotoEase
//
//  Created by Son on 27/02/2025.
//

import UIKit
import Kingfisher

protocol PhotoTableViewCellDelegate: AnyObject {
    func didTapToToggleFavoriteStatus(from cell: PhotoTableViewCell)
}

class PhotoTableViewCell: UITableViewCell {

    var photo: Photo!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var favoriteStatusButton: UIButton!
    
    weak var delegate: PhotoTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.photoImageView.layer.borderWidth = 0.5
        self.photoImageView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        self.photoImageView.layer.cornerRadius = self.photoImageView.bounds.height / 2.0
        
        // Use loading indicator instead of placeholder
        self.photoImageView.kf.indicatorType = .activity
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func config(with photo: Photo) {
        self.photo = photo
        self.photoTitleLabel.text = self.photo.title
        
        // Download then display the photo
        self.photoImageView.kf.cancelDownloadTask()
        if let url = photo.thumbnailUrl {
            let cacheKey = url.absoluteString
            let resource = Kingfisher.KF.ImageResource(downloadURL: url, cacheKey: cacheKey)
            self.photoImageView.kf.setImage(with: resource)
        }
        
        // Favorite status
        let iconName = PhotoDataHelper.shared.isFavoritePhoto(photoId: self.photo.id) ? "star.fill" : "star"
        self.favoriteStatusButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
    
    @IBAction func onTouchToFavoriteStatusButton(_ sender: AnyObject) {
        self.delegate?.didTapToToggleFavoriteStatus(from: self)
    }
    
}
