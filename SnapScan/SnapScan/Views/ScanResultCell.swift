//
//  ScanResultCell.swift
//  SnapScan
//
//  Created by Bryan Fox on 6/7/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

import Foundation

protocol MenuActionDelegate: AnyObject {
    func renameScan(_ id: String, to name: String)
    func exportScan(_ id: String)
    func deleteScan(_ id: String)
}

class ScanResultCell: UICollectionViewCell {
    public static let ReuseIdentifier = "ScanResultCell"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var progressView: UIProgressView!

    weak var menuActionDelegate: MenuActionDelegate?
    var scanId: String?
    let fileManager = MediaFileManager.init()

    func resetView() {
        imageView.image = nil
        nameLabel.text = nil
        dateLabel.text = nil
        activityIndicator.isHidden = true
        progressView.isHidden = true
    }

    func formattedCollectionViewCell(withViewModel viewModel: ScanCellViewModel) -> UICollectionViewCell {
        self.updateViewWithViewModel(viewModel)
        return self
    }

    func updateViewWithViewModel(_ viewModel: ScanCellViewModel) {
        scanId = viewModel.id
        nameLabel.text = viewModel.id

        if viewModel.isScanning {
            dateLabel.text = NSLocalizedString("scanning...", comment: "")
            activityIndicator.startAnimating()
        } else {
            dateLabel.text = prettyDate(viewModel.createdAt)
            activityIndicator.stopAnimating()
        }

        if let progress = viewModel.scanningProgress, viewModel.isScanning == true {
            progressView.isHidden = false
            progressView.progress = Float(progress) / 100.0
        } else {
            progressView.isHidden = true
        }

        if let imgPath = viewModel.previewImage {
            imageView.image = UIImage.init(contentsOfFile: fileManager.url(forDocument: imgPath).path)
        } else {
            imageView.image = nil
        }
    }

    private func prettyDate(_ date: Date) -> String {
        let translatorComment = ""
        switch -1 * date.timeIntervalSinceNow {
        case let t where t < 60:
            return NSLocalizedString("just added", comment: translatorComment)
        case let t where t < 60 * 5:
            return NSLocalizedString("a few minutes ago", comment: translatorComment)
        case let t where t < 60 * 60:
            let format = NSLocalizedString("%d minute(s) ago", comment: translatorComment)
            return String.localizedStringWithFormat(format, Int(t.minutes))
        case let t where t < 60 * 60 * 24:
            let format = NSLocalizedString("%d hour(s) ago", comment: translatorComment)
            return String.localizedStringWithFormat(format, Int(t.hours))
        case let t where t < 60 * 60 * 24 * 100:
            let format = NSLocalizedString("%d day(s) ago", comment: translatorComment)
            return String(format: format, Int(t.days))
        default:
            if let longDate = DateFormatter.dateFormat(fromTemplate: "MM/dd/YY", options: 0, locale: Locale.current) {
                return longDate
            } else {
                return ""
            }
        }
    }

}

// TODO: get this working in the controller
private typealias MenuActions = ScanResultCell
extension MenuActions {
    private var supportedActions: [Selector] {
        return [#selector(rename), #selector(delete(_:)), #selector(exportPDF(_:))]
    }

    func rename(_ sender: Any?) {
        if let scanId = scanId {
            menuActionDelegate?.renameScan(scanId, to:"MyName")
        }
    }

    func exportPDF(_ sender: Any?) {
        if let scanId = scanId {
            menuActionDelegate?.exportScan(scanId)
        }
    }

    override func delete(_ sender: Any?) {
        if let scanId = scanId {
            menuActionDelegate?.deleteScan(scanId)
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return supportedActions.contains(action)
    }

}
