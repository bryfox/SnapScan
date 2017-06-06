//
//  ScanResult.swift
//  SnapScan
//
//  Created by Bryan Fox on 6/5/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

import Foundation
import RealmSwift

enum ScanResultError: Error {
    case realmTemporarilyUnavailable
}

class ScanResult: Object {
    // MARK: - Public properties & methods -

    var name:String? {
        get { return title }
        set(newName) {
            // TODO: decide on best way to deal with throw here
            try? withRealm {
                title = newName
            }
        }
    }
    
    var id: String { return _uuid }
    var createdAt: NSDate { return _createdAt }
    var updatedAt: NSDate { return _updatedAt }

    // MARK: -

    static func all(filter: String?) throws -> Results<ScanResult> {
        let realm = try! getRealm()
        
        var results = realm.objects(self)
        if let filter = filter {
            results = results.filter("title LIKE '*@*'", filter)
        }
        return results
    }
    
    static func get(_ id: String) -> ScanResult? {
        let realm = try! Realm()
        return realm.object(ofType: self, forPrimaryKey: id)
    }
    
    func save() throws {
        try! withRealm({() -> Void in return })
    }
    

    // MARK: - Private -

    // Note: read-only properties are automatically ignored
    override static func ignoredProperties() -> [String] {
        return ["name"]
    }
    
    // MARK: persisted Realm properties:

    private dynamic var _pdfUrl = ""
    private dynamic var _previewImageUrl = ""
    private dynamic var _uuid = NSUUID().uuidString
    private dynamic var _createdAt = NSDate()
    private dynamic var _updatedAt = NSDate()
    
    dynamic var recognizedText: String? = nil
    dynamic var title: String? = nil

    // MARK: -

    override static func primaryKey() -> String? {
        return "_uuid"
    }

    // MARK: -

    private static func getRealm () throws -> Realm {
        guard let realm = try? Realm() else {
            throw ScanResultError.realmTemporarilyUnavailable
        }
        return realm
    }

    
    // MARK: -

    private func withRealm(_ block: () -> Void) throws {
        let realm = try! getRealm()
        
        try! realm.write {
            block()
            _updatedAt = NSDate()
            realm.add(self, update: true)
        }
    }

    private func getRealm () throws -> Realm {
        return try! type(of: self).getRealm()
    }
    
}
