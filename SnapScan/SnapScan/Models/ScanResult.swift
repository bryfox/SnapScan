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

final class ScanResult: Object {

    // Add all wrapping properties
    // Note: read-only properties are automatically ignored
    override static func ignoredProperties() -> [String] {
        return ["name", "previewImage", "pdfFile"]
    }

    // MARK: - Public properties & methods -

    // wrapping private realm properties to provide a facade for Realm updates

    var name:String? {
        get { return title }
        set(newName) {
            try? withRealm {
                title = newName
            }
        }
    }

    var previewImage:String? {
        get {
            return _previewImageUrl
        }
        set(newUrl) {
            try? withRealm {
                _previewImageUrl = newUrl
            }
        }
    }

    var pdfFile:String? {
        get { return _pdfUrl }
        set(newUrl) {
            try? withRealm {
                _pdfUrl = newUrl
            }
        }
    }

    var id: String { return _uuid }
    var createdAt: Date { return _createdAt as Date }
    var updatedAt: Date { return _updatedAt as Date }
    // XXX: prototype only 
    var isScanning: Bool { return _previewImageUrl != nil && _pdfUrl == nil }

    // MARK: -

    // Create and return a persisted model
    static func create() throws -> ScanResult {
        let scan = ScanResult.init()
        try scan.save()
        return scan
    }

    static func create(pdfUrl: String, recognizedText: String, name: String? = nil) -> ScanResult {
        let scan = ScanResult.init()
        scan._pdfUrl = pdfUrl
        scan.recognizedText = recognizedText
        if let name = name {
            scan.title = name
        }
        return scan
    }

    static func all(filter: String? = nil) throws -> Results<ScanResult> {
        let realm = try! getRealm()
        
        var results = realm.objects(self)
        if let filter = filter {
            results = results.filter("title LIKE '*@*'", filter)
        }
        return results.sorted(byKeyPath: "_createdAt", ascending: false)
    }
    
    static func get(_ id: String) -> ScanResult? {
        let realm = try! Realm()
        return realm.object(ofType: self, forPrimaryKey: id)
    }
    
    func save() throws {
        try withRealm({() -> Void in return })
    }
    

    // MARK: - Private -

    // MARK: persisted Realm properties:

    private dynamic var _uuid = NSUUID().uuidString
    private dynamic var _createdAt = NSDate()
    private dynamic var _updatedAt = NSDate()

    private dynamic var _previewImageUrl:String? = nil
    private dynamic var _pdfUrl:String? = nil

    dynamic var recognizedText: String? = nil
    dynamic var title: String? = nil

    // MARK: -

    override static func primaryKey() -> String? {
        return "_uuid"
    }

    // MARK: -

    private static func getRealm () throws -> Realm {
        let realm:Realm
        do {
            realm = try Realm()
        } catch {
            print("Error getting Realm: \(error)")
            throw ScanResultError.realmTemporarilyUnavailable
        }
        return realm
    }

    // MARK: -

    private func withRealm(_ block: () -> Void) throws {
        let realm = try getRealm()
        
        try! realm.write {
            block()
            _updatedAt = NSDate()
            realm.add(self, update: true)
        }
    }

    private func getRealm () throws -> Realm {
        return try type(of: self).getRealm()
    }
    
}

