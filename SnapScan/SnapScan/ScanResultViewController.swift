//
//  ScanResultViewController.swift
//  SnapScan
//
//  Created by Bryan Fox on 6/5/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

import UIKit
import RealmSwift

class ScanResultViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var debugLabel: UILabel!

    let fileManager = MediaFileManager.init()
    let itemsPerRow = 2
    var notificationToken: NotificationToken?
    var dataProvider: ScanResultDataProvider?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Sync data source to view before restarting update listener
        collectionView.reloadData()
        dataProvider?.notificationDelegate = self
        dataProvider?.menuActionDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Ignore updates while hidden
        dataProvider?.notificationDelegate = nil
        dataProvider?.menuActionDelegate = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: guard dataProvider; if nil, show an 'unavailable' view?
        dataProvider = ScanResultDataProvider.init(delegate: self)
        collectionView.dataSource = dataProvider
        collectionView.delegate = self
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.reloadData()
    }
}

extension ScanResultViewController : DataUpdateDelegate {
    // Progress updates don't need animation
    func didUpdateProgressAtIndex(_ index: Int) {
        collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
    }

    func onChange(_ change: RealmCollectionChange<Results<ScanResult>>) {
        guard let collectionView = self.collectionView else { return }

        self.debugLabel.text = "\(dataProvider?.collectionView(collectionView, numberOfItemsInSection: 0) ?? 0) scans"

        switch change {
        case .initial:
            collectionView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            func toIndexPath(index: Int) -> IndexPath {
                return IndexPath(row: index, section: 0)
            }
            collectionView.performBatchUpdates({
                collectionView.insertItems(at: insertions.map(toIndexPath))
                collectionView.deleteItems(at: deletions.map(toIndexPath))
                collectionView.reloadItems(at: modifications.map(toIndexPath))
            }, completion: nil)
            break
        case .error:
            DLog("Error")
        }
    }

}

private typealias ScanManager = ScanResultViewController
extension ScanManager : MenuActionDelegate {
    func renameScan(_ id: String, to name: String) {

    }

    func exportScan(_ id: String) {
        if let scan = ScanResult.get(id), let pdfFile = scan.pdfFile {
            sharePdfFile(fileManager.pdfDocumentDirectory.appendingPathComponent(pdfFile))
        }
    }

    func deleteScan(_ id: String) {
        confirmDeleteScan(id)
    }

    private func confirmDeleteScan(_ id: String) {
        func onConfirmed(_: UIAlertAction) {
            if !ScanResult.delete(id) {
                DLog("Delete failed")
            }
        }
        let okAction = UIAlertAction.init(title: NSLocalizedString("OK", comment:""),
                                          style: UIAlertActionStyle.default,
                                          handler: onConfirmed)

        confirm(NSLocalizedString("Really delete this scan?", comment: ""),
                title: NSLocalizedString("Confirm Deletion", comment: ""),
                confirmAction: okAction)
    }
}

// MARK: -
private typealias CollectionViewDelegate = ScanResultViewController
extension CollectionViewDelegate : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }

    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        customizeMenuItems()
        return true
    }

    func collectionView(_ collectionView: UICollectionView,
                        canPerformAction action: Selector,
                        forItemAt indexPath: IndexPath,
                        withSender sender: Any?) -> Bool {
        // required, despite docs. See ScanResultCell for menu actions
        return false
    }

    func collectionView(_ collectionView: UICollectionView,
                        performAction action: Selector,
                        forItemAt indexPath: IndexPath,
                        withSender sender: Any?) {
        // no-op, but required
    }

    func customizeMenuItems() {
        let menu = UIMenuController.shared
        let shareItem  = UIMenuItem.init(title: NSLocalizedString("Share PDF", comment: ""), action: #selector(ScanResultCell.exportPDF))
//        let renameItem = UIMenuItem.init(title: NSLocalizedString("Rename", comment: ""), action: #selector(ScanResultCell.rename))
        menu.menuItems = [shareItem] //, renameItem
    }

}

private typealias FlowLayoutDelegate = ScanResultViewController
extension FlowLayoutDelegate : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let frameWidth = collectionView.frame.width
        let cols = CGFloat(UIDeviceOrientationIsLandscape(UIDevice.current.orientation) ? itemsPerRow * 2 : itemsPerRow)
        let itemWidth = frameWidth / cols
        return CGSize(width: itemWidth, height: itemWidth)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}

private typealias IBActions = ScanResultViewController
extension IBActions {
    @IBAction func cameraButtonPressed(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            launchCamera()
        } else {
            alert(NSLocalizedString("No camera available on this device", comment: ""))
        }
    }

    @IBAction func refreshPressed(_ sender: Any) {
        collectionView.reloadData()
    }
}

private typealias ImagePicker = ScanResultViewController
extension ImagePicker : UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    fileprivate func launchCamera() {
        let picker = UIImagePickerController.init()
        picker.delegate = self
        picker.sourceType = UIImagePickerControllerSourceType.camera
        picker.showsCameraControls = true
        picker.videoQuality = UIImagePickerControllerQualityType.typeHigh
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureMode.photo
        // TODO: app setting for picker.cameraFlashMode?
        // XXX: for quicker debugging with low-res
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        // Can be very slow: image size + accuracy/engineMode are the two main vars.
        // TODO: add resizing (app setting?)
        // XXX: see allowsEditing above
                guard let img = info[UIImagePickerControllerEditedImage] as? UIImage else {
//        guard let img = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                    alert(NSLocalizedString("Image not available", comment: ""))
            return
        }

        do {
            try beginScan(withImage: img)
        } catch ScanningError.couldNotBeCreated {
            alert(NSLocalizedString("Scan could not be created", comment: ""))
        } catch {
            alert(NSLocalizedString("An unknown error occurred", comment: ""))
        }

        // TODO: scroll to top...
        picker.dismiss(animated: true, completion: nil)
        picker.delegate = nil
    }

}

enum ScanningError: Error {
    case couldNotBeCreated
}

private typealias Scanning = ScanResultViewController
extension Scanning {
    static let PreviewJpgCompressionLevel = 0.80

    fileprivate func beginScan(withImage image: UIImage) throws {
        guard let scan = try? ScanResult.create() else {
            throw ScanningError.couldNotBeCreated
        }
        // TODO: Save original image separately
        let previewOp = operationForPreview(image: image, scanIdentifier: scan.id)
        let scanningOp = operationForScanning(image: image, scanIdentifier: scan.id)
        let backgroundQueue = OperationQueue.init()
        backgroundQueue.addOperations([previewOp, scanningOp], waitUntilFinished: false)
    }

    private func operationForPreview(image: UIImage, scanIdentifier: String) -> Operation {
        let previewOp: Operation = BlockOperation.init {
            if let scanCopy = ScanResult.get(scanIdentifier) {
                if let savedImagePath = self.savePreviewImage(image, toScan: scanCopy) {
                    scanCopy.previewImage = savedImagePath
                }
            } else {
                print("failed to fetch!")
            }
        }
        previewOp.qualityOfService = QualityOfService.userInitiated
        return previewOp
    }

    private func operationForScanning(image: UIImage, scanIdentifier: String) -> Operation {
        // TODO: handle errors (display error state).
        let scanningOp: Operation = BlockOperation.init {
            guard let scanCopy = ScanResult.get(scanIdentifier) else {
                //retry/error
                print("failed to fetch!")
                return
            }
            guard let scanner = PDFScanner.init(identifier: scanIdentifier) else {
                print("scanner failed...")
                return
            }

            scanner.progressDelegate = self.dataProvider
            // TODO: Accuracy prefs
            guard let pdfFile = scanner.savePDF(from: image, with: PDFScannerAccuracyLow) else {
                print("Scan failed!")
                return
            }

            // TODO: the viewmodel needs to be set as finished?
//            scanCopy.scanningProgress = 100
            scanCopy.pdfFile = pdfFile
        }
        scanningOp.qualityOfService = QualityOfService.userInitiated
        return scanningOp
    }

    private func savePreviewImage(_ image: UIImage, toScan scanResult: ScanResult) -> String? {
        // TODO: preview scaling
        let filename = (scanResult.id as NSString).appendingPathExtension("jpg")!

        guard let imgDir = fileManager.previewDocumentDirectory else {
            print("img directory unavailable")
            return nil
        }

        do {
            let jpgData = UIImageJPEGRepresentation(image, CGFloat(Scanning.PreviewJpgCompressionLevel))
            try jpgData?.write(to: imgDir.appendingPathComponent(filename))
        } catch {
            print("Error saving preview")
        }

        // return value will not contain the full path (only the subdir + filename)
        return (fileManager.imageDirectoryName as NSString).appendingPathComponent(filename)
    }

}

private typealias Alerts = ScanResultViewController
extension Alerts {
    fileprivate func confirm(_ message: String, title: String, confirmAction: UIAlertAction) {
        let confirm = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment:""),
                                             style: UIAlertActionStyle.cancel, handler: nil)
        confirm.addAction(confirmAction)
        confirm.addAction(cancelAction)
        present(confirm, animated: true)
    }
    fileprivate func alert(_ message: String, title: String = NSLocalizedString("Alert", comment: "Alert popup title")) {
        let alert = UIAlertController.init(title: title,
                                           message: message,
                                           preferredStyle: UIAlertControllerStyle.alert)
        let alertAction = UIAlertAction.init(title: NSLocalizedString("OK", comment:""),
                                             style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true)
    }
}

private typealias ShareSheet = ScanResultViewController
extension ShareSheet {
    fileprivate func sharePdfFile(_ fileURL: URL) {
        let shareSheet = UIActivityViewController.init(activityItems: [fileURL], applicationActivities: nil)
        present(shareSheet, animated: true)
    }
}
