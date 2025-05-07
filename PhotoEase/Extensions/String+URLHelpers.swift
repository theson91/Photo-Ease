//
//  StringExtension.swift
//  PhotoEase
//
//  Created by Son on 02/03/2025.
//

import Foundation

extension String {
    
    // Validate the given URL string to check if it is valid or not
    func isValidURL() -> Bool {
        guard let url = URL(string: self),
              let scheme = url.scheme,
              let host = url.host else {
            return false
        }
        return ["http", "https"].contains(scheme) && !host.isEmpty
    }
    
    // To replace 'via.placeholder.com' with 'dummyimage.com'
    func replaceThePlaceholderDomain() -> String {
        return self.replacingOccurrences(of: "via.placeholder.com", with: "dummyimage.com")
    }
}
