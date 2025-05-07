//
//  LoadMoreTableViewCell.swift
//  PhotoEase
//
//  Created by Son on 28/02/2025.
//

import UIKit

class LoadMoreTableViewCell: UITableViewCell {
    
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func startLoading() {
        self.loadingActivityIndicator.startAnimating()
    }
    
}
