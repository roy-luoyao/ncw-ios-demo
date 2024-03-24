//
//  TransfersViewModel.swift
//  Fireblocks
//
//  Created by Fireblocks Ltd. on 06/07/2023.
//

import Foundation
import UIKit.UIImage

enum NotificationType {
    case notification
    case error
    
    func getImage() -> UIImage {
        switch self {
        case .notification:
            return AssetsIcons.transferImage.getIcon()
        case .error:
            return AssetsIcons.errorImage.getIcon()
        }
    }
    
    func getMessage() -> String {
        switch self {
        case .notification:
            return "You don’t have any transfers yet."
        case .error:
            return "failed to load transactions,\n please try to refresh."
        }
    }
    
    func isRefreshButtonNeeded() -> Bool {
        switch self {
        case .notification:
            return false
        case .error:
            return true
        }
    }
}

protocol TransfersViewModelDelegate: AnyObject {
    func transfersUpdated()
    func showNotification(type: NotificationType)
}


final class TransfersViewModel: ObservableObject {
    
    static let shared = TransfersViewModel()
    
    @Published var transfers: [TransferInfo] = []
    weak var delegate: TransfersViewModelDelegate?
    private var task: Task<Void, Never>?
    private var didRequestAlltransactions = false
    deinit {
        task?.cancel()
    }
    
    func signOut() {
        transfers.removeAll()
    }
    
    var sortedTransfer: [TransferInfo] {
        return transfers.filter({$0.lastUpdated != nil}).sorted(by: {$0.lastUpdated! > $1.lastUpdated!})
    }
    
    func handleTransactions(transactions: [TransactionResponse]) {
        if transfers.isEmpty {
            transfers = transactions.map({$0.toTransferInfo()})
        } else {
            for transaction in transactions {
                let transferInfo = transaction.toTransferInfo()
                if let index = transfers.firstIndex(where: {$0.transactionID == transferInfo.transactionID}) {
                    if transfers[index].lastUpdated != transferInfo.lastUpdated {
                        transfers[index] = transferInfo
                        print("TRANSFER_UPDATED: \(transferInfo)")
                    }

                } else {
                    transfers.append(transferInfo)
                    print("TRANSFER_ADDED: \(transferInfo)")
                }
            }
        }
        
        if transactions.count > 0 {
            updateUI()
        }
    }
    
    func lastUpdate() -> TimeInterval? {
        return transfers.filter({$0.lastUpdated != nil}).map({$0.lastUpdated!}).max()
    }
    

    func getTransferFor(index: Int) -> TransferInfo {
        return sortedTransfer[index]
    }
    
    func getTransfersCount() -> Int {
        return transfers.count
    }
    
    private func updateUI(){
        if transfers.isEmpty {
            delegate?.showNotification(type: .notification)
        } else {
            delegate?.transfersUpdated()
            AssetListViewModel.shared.fetchAssets()
        }

    }
    
    func refresh() {
    }
    
    func getTransferData(for index: Int) -> TransferInfo {
        return sortedTransfer[index]
    }
    
    func updateStatusWhenApproved(index: Int) {
        transfers[index].status = .Confirming
        updateUI()
    }
}
