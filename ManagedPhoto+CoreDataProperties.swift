//
//  ManagedPhoto+CoreDataProperties.swift
//  PhotoEase
//
//  Created by Son on 27/02/2025.
//
//

import Foundation
import CoreData


extension ManagedPhoto {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedPhoto> {
        return NSFetchRequest<ManagedPhoto>(entityName: "ManagedPhoto")
    }

    @NSManaged public var albumId: Int16
    @NSManaged public var id: Int16
    @NSManaged public var order: Int16
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var thumbnailUrl: String?

}

extension ManagedPhoto : Identifiable {

}
