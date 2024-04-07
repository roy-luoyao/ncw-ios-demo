//
//  FeeRateViewModel.swift
//  Fireblocks
//
//  Created by Fireblocks Ltd. on 05/07/2023.
//

import Foundation
import Combine

protocol FeeRateViewModelDelegate: AnyObject {
    func refreshData()
    func isTransactionCreated(isCreated: Bool)
}

final class FeeRateViewModel {
    //MARK: - PROPERTIES
    var transaction: Transaction?
    private var fees: [Fee] = []
    private var selectedFeeIndex: Int = 0
    private let repository = FeeRateRepository()
    private var tasks: [Task<Void, Never>]?
    weak var delegate: FeeRateViewModelDelegate?
    private var transactionID: String?
    private var didPresented = false
    private var cancellable = Set<AnyCancellable>()
    
    //MARK: - FUNCTIONS
    deinit {
        cancellable.removeAll()
        tasks?.forEach{ $0.cancel() }
    }
    
    func isContinueButtonEnabled() -> Bool {
        if fees.count == 0 { return false }
        if selectedFeeIndex == nil { return false }
        
        return true
    }
    
    func fetchFeeRates(){
        guard let transaction = transaction else { return }
        guard let destAddress = transaction.receiverAddress else { return }
        let assetId = transaction.asset.id
        let amount = transaction.amountToSend
        
        Task {
            do {
                fees = try await repository.getFeeRates(for: assetId, amount: "\(amount)", address: destAddress)
                delegate?.refreshData()
            } catch let error {
                print(error)
                delegate?.isTransactionCreated(isCreated: false)
            }
        }
    }
    
    func getFees() -> [Fee] {
        fees
    }
    
    func getFeesCount() -> Int {
        fees.count
    }
    
    func getSelectedIndex() -> Int? {
        return selectedFeeIndex
    }
    
    func selectFee(at index: Int) {
        selectedFeeIndex = index
    }
    
    func getTransaction() -> Transaction? {
        if var transaction = transaction, let txId = transactionID {
            if fees.count > selectedFeeIndex {
                transaction.fee = fees[selectedFeeIndex]
            } else {
                transaction.fee = nil
            }
            transaction.txId = txId
            return transaction
        } else {
            return nil
        }
    }
    
    func createTransaction(){
        guard let transaction = transaction else {
            print("❌ Transaction nil")
            return
        }
        
        guard let senderAddress = transaction.asset.address else {
            print("❌ senderAddress nil")
            return
        }
        
        guard let receiverAddress = transaction.receiverAddress else {
            print("❌ receiverAddress nil")
            return
        }
        
        guard fees.count > selectedFeeIndex else {
            print("❌ selectedFeeIndex nil")
            return
        }
        
        listenToTransactionStatusChanges()
        
        let transactionParams = PostTransactionParams(assetId: transaction.asset.id, destAddress: receiverAddress,
                                                      amount: "\(transaction.amountToSend)",
                                                      note: "test transaction",
                                                      feeLevel: fees[selectedFeeIndex].feeRateType.rawValue)
        
        let task = Task {
            do {
                let response = try await repository.createTransaction(assetId: transaction.asset.id, transactionParams: transactionParams)
                self.transactionID = response.id
                print("TRANSFER_ADDED - RESPONSE: \(response)")
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        tasks?.append(task)
    }
    
    private func listenToTransactionStatusChanges() {
        let failedStatus: [TransferStatusType] = [.Failed, .Blocked, .Cancelled, .Rejected]
        TransfersViewModel.shared.$transfers.receive(on: RunLoop.main)
            .sink { [weak self] transfers in
                print("TRANSFER_ADDED - new transfer status: \(transfers)")
                if let self {
                    if let transactionID = self.transactionID, let transaction = transfers.first(where: {$0.transactionID == transactionID}) {
                        print("TRANSFER_ADDED - new transfer status: \(transaction.status.rawValue)")
                        let status = transaction.status
                        if status == .PendingSignature, !self.didPresented {
                            self.didPresented = true
                            self.delegate?.isTransactionCreated(isCreated: true)
                        } else if failedStatus.contains(status) {
                            self.delegate?.isTransactionCreated(isCreated: false)
                        }
                    }
                }
            }.store(in: &cancellable)
    }
    
}
