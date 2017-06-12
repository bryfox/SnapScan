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
    case deleteFailed
}

final class ScanResult: Object {
    // Add all wrapping properties
    // Note: read-only properties are automatically ignored
    override static func ignoredProperties() -> [String] {
        return ["name", "previewImage", "pdfFile"]
    }

    // MARK: - Public properties & methods -

    // wrapping private realm properties to provide a facade for Realm updates

    var name: String? {
        get { return title }
        set(newName) {
            try? withRealm {
                title = newName
            }
        }
    }

    var previewImage: String? {
        get { return _previewImageUrl }
        set(newUrl) {
            try? withRealm {
                _previewImageUrl = newUrl
            }
        }
    }

    var pdfFile: String? {
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

    static func delete(_ id: String) -> Bool {
        guard let realm = try? getRealm(), let scan = realm.object(ofType: self, forPrimaryKey: id) else {
            return false
        }
        do {
            let pdfPath = scan.pdfFile
            let previewPath = scan.previewImage
            let fm = MediaFileManager.init()
            realm.beginWrite()
            realm.delete(scan)
            try realm.commitWrite()
            // Once realm write is committed, delete files
            try? fm.deleteDocument(atPath: pdfPath)
            try? fm.deleteDocument(atPath: previewPath)
        } catch {
            print("Delete failed: \(error)")
            realm.cancelWrite()
            return false
        }
        return true
    }

    static func all(filter: String? = nil) throws -> Results<ScanResult> {
        let realm = try getRealm()

        var results = realm.objects(self)
        if let filter = filter {
            results = results.filter("title LIKE '*@*'", filter)
        }
        return results.sorted(byKeyPath: "_createdAt", ascending: false)
    }

    static func get(_ id: String) -> ScanResult? {
        let realm = try? Realm()
        return realm?.object(ofType: self, forPrimaryKey: id)
    }

    func save() throws {
        try withRealm({() -> Void in return })
    }

    // MARK: - Private -

    // MARK: persisted Realm properties:
    override static func indexedProperties() -> [String] {
        return ["_createdAt"]
    }

    private dynamic var _uuid = NSUUID().uuidString
    private dynamic var _createdAt = NSDate()
    private dynamic var _updatedAt = NSDate()

    private dynamic var _previewImageUrl: String?
    private dynamic var _pdfUrl: String?

    dynamic var recognizedText: String?
    dynamic var title: String?

    // MARK: -

    override static func primaryKey() -> String? {
        return "_uuid"
    }

    // MARK: -

    private static func getRealm () throws -> Realm {
        let realm: Realm
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
        try withRealm({(_: Realm) -> Void in
             block()
        })
    }

    private func withRealm(_ block: (Realm) -> Void) throws {
        let realm = try getRealm()
        try realm.write {
            block(realm)
            _updatedAt = NSDate()
            realm.add(self, update: true)
        }
    }

    private func getRealm () throws -> Realm {
        return try type(of: self).getRealm()
    }
}
