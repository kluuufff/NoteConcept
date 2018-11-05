//
//  Notes.swift
//  NoteConcept
//
//  Created by Nadiya on 11/5/18.
//  Copyright © 2018 Nadiya. All rights reserved.
//

import Foundation
import CoreData

@objc(Notes)
class Notes: NSManagedObject {
    @NSManaged var note: String?
    @NSManaged var date: String?
    @NSManaged var id: NSNumber?
}
