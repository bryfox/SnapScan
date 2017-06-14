//
//  ScanCellViewModel.swift
//  SnapScan
//
//  Created by Bryan Fox on 6/12/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

import Foundation

struct ScanCellViewModel {
    var scanResult: ScanResult!

    var id: String { return scanResult.id }
    var isScanning: Bool { return scanResult.isScanning }
    var createdAt: Date { return scanResult.createdAt }
    var previewImage: String? { return scanResult.previewImage }
    var pdfFile: String? { return scanResult.pdfFile }

    /// Decorate model with temporary progress state
    /// Value from 0..100 representing percent complete.
    var scanningProgress: Int?

    var pdfUrl: URL? {
        return fileManager.url(forDocument: scanResult.pdfFile)
    }

    private var fileManager = MediaFileManager()

    init(scanResult: ScanResult) {
        self.scanResult = scanResult
    }

    init(scanResult: ScanResult, progress: Int) {
        self.scanResult = scanResult
        scanningProgress = progress
    }

}
