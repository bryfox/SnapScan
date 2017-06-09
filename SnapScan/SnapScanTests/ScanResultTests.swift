//
//  ScanResultTests.swift
//  SnapScan
//
//  Created by Bryan Fox on 6/5/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

import XCTest
import RealmSwift

@testable import SnapScan

//@testable import ScanResult

class ScanResultTests: XCTestCase {
    var realm:Realm? = nil

    override func setUp() {
        super.setUp()

        // Use an in-memory Realm identified by the name of the current test.
        // See https://realm.io/docs/swift/latest/#configuring-the-default-realm
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
        realm = try! Realm()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        realm = nil
    }
    
    func testGetMissing() {
        let result = ScanResult.get("doesnotexist")
        XCTAssertNil(result, "should be nil")
    }
    
    func testResultCreation() {
        let newScan = ScanResult.init()
        try! newScan.save()
        let result:ScanResult! = ScanResult.get(newScan.id)
        XCTAssertEqual(result.id, newScan.id, "doesn't match")
    }

    func testTimestampSetting() {
        let newScan = ScanResult.init()
        try! newScan.save()
        let result:ScanResult! = ScanResult.get(newScan.id)
        let createDiff = result.createdAt.timeIntervalSinceNow
        let updateDiff = result.updatedAt.timeIntervalSinceNow
        XCTAssert(createDiff < 0.1, "created date incorrect")
        XCTAssert(updateDiff < 0.1, "updated date incorrect")
    }

    func testUpdate() {
        let name = "custom name"
        let newScan = ScanResult.init()
        newScan.name = "first"
        try! newScan.save()
        newScan.name = name
        let result:ScanResult! = ScanResult.get(newScan.id)
        XCTAssertEqual(result.name, name, "name was not saved")
    }

    func testUpdateTimestamp() {
        let newScan = ScanResult.init()
        try! newScan.save()
        let firstTime = newScan.updatedAt
        newScan.name = "update anything here"
        XCTAssertNotEqual(firstTime, newScan.updatedAt, "timestamp was not updated")
    }

    func testDeletion() {
        let newScan = ScanResult.init()
        let scanId = newScan.id
        try! newScan.save()
        XCTAssertNotNil(realm?.object(ofType: ScanResult.self, forPrimaryKey: scanId))
        let success = ScanResult.delete(scanId)
        XCTAssertTrue(success)
        XCTAssertNil(realm?.object(ofType: ScanResult.self, forPrimaryKey: scanId))
    }
}
