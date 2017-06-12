//
//  ScanResultDataProvider.swift
//  SnapScan
//
//  Created by Bryan Fox on 6/14/17.
//  Copyright © 2017 Bryan Fox. All rights reserved.
//

import Foundation
import RealmSwift

// TODO: abstract realm away here & make interface use IndexPaths
// This is a class-only protocol so we can maintain weak ref to delegate
protocol DataUpdateDelegate: AnyObject {
    /// Progress updates should be lightweight and are notified separately
    func didUpdateProgressAtIndex(_ index: Int)
    func onChange(_ change: RealmCollectionChange<Results<ScanResult>>)
}

class ScanResultDataProvider: NSObject {
    weak var notificationDelegate: DataUpdateDelegate?
    weak var menuActionDelegate: MenuActionDelegate?

    // Scan results kept in sync automatically by Realm
    fileprivate var queryResults: Results<ScanResult>!
    fileprivate var _viewModels: [ScanCellViewModel]! = []
    private var changeToken: NotificationToken?

    var viewModels: [ScanCellViewModel] { return _viewModels }

    convenience init?(delegate: DataUpdateDelegate & MenuActionDelegate) {
        self.init(dataUpdateDelegate: delegate, menuActionDelegate: delegate)
        if queryResults == nil {
            return nil
        }
    }

    init?(dataUpdateDelegate: DataUpdateDelegate, menuActionDelegate: MenuActionDelegate) {
        super.init()

        guard let results = try? ScanResult.all() else {
            print("Query results unavailable")
            return nil
        }

        self.notificationDelegate = dataUpdateDelegate
        self.menuActionDelegate = menuActionDelegate
        queryResults = results
        changeToken = results.addNotificationBlock(realmNotificationHandler(change:))
    }

    func realmNotificationHandler(change: RealmCollectionChange<Results<ScanResult>>) {
        switch change {
        case .initial:
            self._viewModels = queryResults.map({ scanResult in ScanCellViewModel.init(scanResult: scanResult) })
        case .update(_, let deletions, let insertions, let modifications):
            deletions.forEach({ (index) in
                self._viewModels.remove(at: index)
            })

            insertions.forEach({ (index: Int) in
                if let result = queryResults?[index] {
                    self._viewModels.insert(ScanCellViewModel(scanResult: result), at: index)
                }
            })

            modifications.forEach({ (index: Int) in
                if let result = queryResults?[index] {
                    self._viewModels.replaceSubrange(index..<index+1, with: [ScanCellViewModel(scanResult: result)])
                }
            })

        case .error(let error):
            DLog("Realm Notification Error: \(error)")
            // Note: This callback will never be called again!
            // TODO: decide on error handling
        }

        notificationDelegate?.onChange(change)
    }

    deinit {
        changeToken = nil
    }
}

extension ScanResultDataProvider : PDFScannerProgressDelegate {
    func didUpdateProgress(_ progress: Int, forIdentifier identifier: String!) {
        if let index = queryResults?.index(where: { $0.id == identifier }), let scanResult = queryResults?[index] {
            let vm = ScanCellViewModel(scanResult: scanResult, progress: progress)
            _viewModels.replaceSubrange(index..<index+1, with: [vm])
            notificationDelegate?.didUpdateProgressAtIndex(index)
        }
    }
}

private typealias CollectionViewDataSource = ScanResultDataProvider
extension CollectionViewDataSource : UICollectionViewDataSource {
    func scanAtIndexPath(_ indexPath: IndexPath) -> ScanCellViewModel? {
        return viewModels[indexPath.row]
    }

    func indexPathOfScanId(_ id: String) -> IndexPath? {
        if let index = viewModels.index(where: { $0.id == id }) {
            return IndexPath(row: index, section: 0)
        } else {
            return nil
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ScanResultCell.ReuseIdentifier, for: indexPath) as! ScanResultCell

        guard let scan: ScanCellViewModel = scanAtIndexPath(indexPath) else {
            DLog("Scan not found at index path \(indexPath)")
            cell.resetView()
            return cell
        }

        cell.menuActionDelegate = self.menuActionDelegate
        return cell.formattedCollectionViewCell(withViewModel: scan)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModels.count
    }

}
