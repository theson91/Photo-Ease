//
//  Photo.swift
//  PhotoEase
//
//  Created by Son on 27/02/2025.
//

import Foundation

enum PhotoCodingKey: String, CodingKey {
    case albumId
    case id
    case title
    case url
    case thumbnailUrl
}

struct Photo: Codable {
    let albumId: Int
    let id: Int
    let title: String
    var url: URL?
    var thumbnailUrl: URL?
    
    // Decode from JSON data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PhotoCodingKey.self)
        self.albumId = try container.decode(Int.self, forKey: .albumId)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        
        // Decoding URLs
        if let urlString = try container.decodeIfPresent(String.self, forKey: .url)?.replaceThePlaceholderDomain(), urlString.isValidURL() {
            self.url = URL(string: urlString)
        } else {
            self.url = nil
        }
        
        if let thumbnailString = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)?.replaceThePlaceholderDomain(), thumbnailString.isValidURL() {
            self.thumbnailUrl = URL(string: thumbnailString)
        } else {
            self.thumbnailUrl = nil
        }
    }
    
    // Initialize from a ManagedPhoto object
    init(fromManagedPhoto managedPhoto: ManagedPhoto) {
        self.albumId = Int(managedPhoto.albumId)
        self.id = Int(managedPhoto.id)
        self.title = managedPhoto.title ?? ""
        self.url = managedPhoto.url.flatMap { URL(string: $0) }
        self.thumbnailUrl = managedPhoto.thumbnailUrl.flatMap { URL(string: $0) }
    }
}

