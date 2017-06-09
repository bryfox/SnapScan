//
//  ScanResultCell.swift
//  SnapScan
//
//  Created by Bryan Fox on 6/7/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

import Foundation

class ScanResultCell: UICollectionViewCell {
    public static let ReuseIdentifier = "ScanResultCell"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    weak var scanResultController: ScanResultViewController?
    var scanId: String?
}

private typealias MenuActions = ScanResultCell
extension MenuActions {
    private var supportedActions: [Selector] {
        return [#selector(rename), #selector(delete(_:)), #selector(exportPDF(_:))]
    }

    func rename(_ sender: Any?) {
        if let scanId = scanId {
            scanResultController?.renameScan(scanId, to:"MyName")
        }
    }

    func exportPDF(_ sender: Any?) {
        if let scanId = scanId {
            scanResultController?.exportScan(scanId)
        }
    }

    override func delete(_ sender: Any?) {
        if let scanId = scanId {
            scanResultController?.deleteScan(scanId)
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return supportedActions.contains(action)
    }

}
