//
//  PhotoDataHelper.swift
//  PhotoEase
//
//  Created by Son on 27/02/2025.
//

import Foundation
import CoreData

class PhotoDataHelper {
    
    static let shared = PhotoDataHelper()
    
    // The key for storing favorite photo ids in UserDefaults
    private let favoritePhotoIdsKey = "favoritePhotoIds"
    
    var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreData")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    private func saveContext() {
        let context = self.persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let anError = error as NSError
                fatalError("Error happens \(anError), \(anError.localizedDescription)")
            }
        }
    }
}

// MARK: - Handle create/delete managed photos
extension PhotoDataHelper {
    func getAllManagedPhotos() -> [ManagedPhoto] {
        let fetchRequest: NSFetchRequest<ManagedPhoto> = ManagedPhoto.fetchRequest()
        do {
            let managedPhotos = try self.persistentContainer.viewContext.fetch(fetchRequest)
            return managedPhotos // Successfully fetched and return the array of ManagedPhoto
        } catch let error as NSError {
            debugPrint("Error happens when fetching managed photos: \(error), \(error.userInfo)")
            return [] // Return an empty array in case of error
        }
    }
    
    func createNewManagedPhoto(from photo: Photo) {
        let newObject = ManagedPhoto(context: self.persistentContainer.viewContext)
        newObject.albumId = Int16(photo.albumId)
        newObject.id = Int16(photo.id)
        newObject.title = photo.title
        newObject.url = photo.url?.absoluteString ?? ""
        newObject.thumbnailUrl = photo.thumbnailUrl?.absoluteString ?? ""
        
        do {
            try self.persistentContainer.viewContext.save()
            self.toggleFavoriteStatus(photoId: photo.id)
        } catch let error as NSError {
            debugPrint("Error happens when creating a new managed photo \(error), \(error.localizedDescription)")
        }
    }
    
    func deleteManagedPhoto(byId photoId: Int) {
        let fetchRequest: NSFetchRequest<ManagedPhoto> = ManagedPhoto.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", Int16(photoId))
        
        do {
            let results = try self.persistentContainer.viewContext.fetch(fetchRequest)
            if let photoToDelete = results.first {
                self.persistentContainer.viewContext.delete(photoToDelete)
                saveContext()
                self.toggleFavoriteStatus(photoId: photoId)
            } else {
                debugPrint("No photo found with ID \(photoId)")
            }
        } catch let error as NSError {
            debugPrint("Error happens when deleting a managed photo: \(error), \(error.localizedDescription)")
        }
    }
}

// MARK: - Handle favorite status
extension PhotoDataHelper {
    private var favoritePhotoIds: Set<Int> {
        get { Set(UserDefaults.standard.array(forKey: self.favoritePhotoIdsKey) as? [Int] ?? []) }
        
        set {
            UserDefaults.standard.set(Array(newValue), forKey: self.favoritePhotoIdsKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func toggleFavoriteStatus(photoId: Int) {
        if self.favoritePhotoIds.contains(photoId) {
            self.favoritePhotoIds.remove(photoId)
        } else {
            self.favoritePhotoIds.insert(photoId)
        }
    }
        
    func isFavoritePhoto(photoId: Int) -> Bool {
        self.favoritePhotoIds.contains(photoId)
    }
}
