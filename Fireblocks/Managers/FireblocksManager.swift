//
//  FireblocksManager.swift
//  Fireblocks
//
//  Created by Fireblocks Ltd. on 10/07/2023.
//

import FireblocksDev
import FirebaseAuth
import Foundation
import OSLog

private let logger = Logger(subsystem: "Fireblocks", category: "FireblocksManager")
protocol FireblocksKeyCreationDelegate {
    func isKeysGenerated(isGenerated: Bool, didJoin: Bool, error: String?)
}

class FireblocksManager {
    
    static let shared = FireblocksManager()
    
    private var deviceId: String = ""
    private var walletId: String = ""

    private init() {
    }
    
    func getDeviceId() -> String {
        return deviceId
    }
    
    func getWalletId() -> String {
        return walletId
    }
    
    func isKeyInitialized(algorithm: Algorithm) -> Bool {
        return getMpcKeys().filter({$0.algorithm == algorithm}).first?.keyStatus == .READY
    }

    func isInstanceInitialized(authUser: AuthUser?) -> Bool {
        guard let deviceId = authUser?.deviceId,
              let walletId = authUser?.walletId
        else {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, initInstance() failed: user credentials is nil")
            return false
        }
        
        self.deviceId = deviceId
        self.walletId = walletId
        
        do {
            try initializeFireblocksSDK()
            return true
        } catch {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, initInstance() throws exc: \(error).")
            return false
        }
    }
        
    func getSdkInstance() -> FireblocksDev.Fireblocks? {
        do {
            return try Fireblocks.getInstance(deviceId: deviceId)
        } catch {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, getFireblocksInstance() can't get instance: \(error).")
            return nil
        }
    }
    
    func generateDeviceId() -> String {
        return Fireblocks.generateDeviceId()
    }
    
    func generatePassphraseId() -> String {
        return Fireblocks.generatePassphraseId()
    }
    
    func generateMpcKeys(_ delegate: FireblocksKeyCreationDelegate) async {
        do {
            let algorithms: Set<Algorithm> = Set([.MPC_ECDSA_SECP256K1, .MPC_EDDSA_ED25519])
            let startDate = Date()
            let result = try await getSdkInstance()?.generateMPCKeys(algorithms: algorithms)
            print("Measure - generateMpcKeys \(Date().timeIntervalSince(startDate))")
            let isGenerated = result?.first?.keyStatus == .READY
            AppLoggerManager.shared.logger()?.log("FireblocksManager, generateMpcKeys() isGenerated value: \(isGenerated).")

            if isGenerated {
                //We simulate a simple way to implement a Polling mechanism.
                //During the integration it is ineeded to generate a mechanism for fetching and listening to incoming messages and transactions, which could be any implementation (e.g. polling, web-socket, push etc.)
                startPolling()
            }
            
            delegate.isKeysGenerated(isGenerated: isGenerated, didJoin: false, error: nil)
        } catch {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, generateMpcKeys() failed: \(error).")
        }
    }
    
    func startPolling() {
        PollingManager.shared.createListener(deviceId: deviceId, instance: self, sessionManager: SessionManager.shared)
    }
    
    func signTransaction(transactionId: String) async -> Bool {
        do {
            let startDate = Date()
            let result = try await getSdkInstance()?.signTransaction(txId: transactionId)
            print("Measure - signTransaction \(Date().timeIntervalSince(startDate))")

            return result?.transactionSignatureStatus == .COMPLETED
        } catch let err as FireblocksError {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, signTransaction() failed: \(err.description).")
            return false
        } catch {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, signTransaction() failed: \(error.localizedDescription).")
            return false
        }
    }
    
    func addDevice(_ delegate: FireblocksKeyCreationDelegate, joinWalletHandler: FireblocksJoinWalletHandler) async {
        do {
            let startDate = Date()
            let result = try await getSdkInstance()?.requestJoinExistingWallet(joinWalletHandler: joinWalletHandler)
            print("Measure - addDevice \(Date().timeIntervalSince(startDate))")

            let isGenerated = result?.first?.keyStatus == .READY
            if isGenerated {
                startPolling()
            }
            delegate.isKeysGenerated(isGenerated: isGenerated, didJoin: true, error: nil)
        } catch let err as FireblocksError {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, addDevice() failed: \(err.description).")
            delegate.isKeysGenerated(isGenerated: false, didJoin: false, error: err.description)
        } catch {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, addDevice() failed: \(error.localizedDescription).")
            delegate.isKeysGenerated(isGenerated: false, didJoin: false, error: error.localizedDescription)
        }
    }
    
    func approveJoinWallet(requestId: String) async throws -> Set<FireblocksDev.JoinWalletDescriptor> {
        let instance = try Fireblocks.getInstance(deviceId: deviceId)
        return try await instance.approveJoinWalletRequest(requestId: requestId)
    }
    
    func getMpcKeys() -> [KeyDescriptor] {
        return getSdkInstance()?.getKeysStatus() ?? []
    }
    
    func getFullKey() async -> [String: Data]? {
        guard getSdkInstance() != nil else {
            return nil
        }
        
        var keysSet: Set<String> = []
        let allKeys = getMpcKeys()
        for mpcKey in allKeys {
            keysSet.insert(mpcKey.keyId)
        }
            
        return nil
    }
    
    func takeOver() async -> Set<FullKey>? {
        guard let instance = getSdkInstance() else {
            return nil
        }
        
        do {
            return try await instance.takeover()
        } catch {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, Takeover() can't takeover keys: \(error).")
            return nil
        }
    }
    
    func deriveAssetKey(privateKey: String, derivationParams: DerivationParams) async -> KeyData? {
        guard let instance = getSdkInstance() else {
            return nil
        }
        
        do {
            return try await instance.deriveAssetKey(extendedPrivateKey: privateKey, bip44DerivationParams: derivationParams)
        } catch {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, deriveAssetKey failed: \(error).")
            return nil
        }
    }

    
    func recoverWallet(resolver: FireblocksPassphraseResolver) async -> Bool {
        guard let instance = getSdkInstance() else {
            return false
        }
        
        do {
            let keySet = try await instance.recoverKeys(passphraseResolver: resolver)
            if keySet.isEmpty { return false }
            if keySet.first(where: {$0.keyRecoveryStatus == .ERROR}) != nil  { return false }
            startPolling()
            return true
        } catch {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, recoverWallet() can't recover wallet: \(error).")
            return false
        }
    }
    
    func generatePassphrase() -> String {
        return Fireblocks.generateRandomPassPhrase()
    }
    
    func backupKeys(passphrase: String, passphraseId: String) async -> Set<FireblocksDev.KeyBackup>? {
        guard let instance = getSdkInstance() else {
            return nil
        }
        
        do {
            return try await instance.backupKeys(passphrase: passphrase, passphraseId: passphraseId)
        } catch {
            AppLoggerManager.shared.logger()?.log("FireblocksManager, backupKeys(): \(error).")
            return nil
        }
    }
    
    private func initializeFireblocksSDK() throws {
        if getSdkInstance() == nil {
            let _ = try Fireblocks.initialize(
                deviceId: deviceId,
                messageHandlerDelegate: self,
                keyStorageDelegate: KeyStorageProvider(deviceId: self.deviceId),
                fireblocksOptions: FireblocksOptions(env: EnvironmentConstants.env, eventHandlerDelegate: self, logLevel: .debug)
            )
        }
    }
    
    func stopPollingMessages() {
        PollingManager.shared.removeListener(deviceId: deviceId)
    }

    func stopJoinWallet() {
        getSdkInstance()?.stopJoinWallet()
    }
    
    private func isAllKeysBackedUp(_ keyBackupSet: Set<FireblocksDev.KeyBackup>) -> Bool {
        for status in keyBackupSet {
            if status.keyBackupStatus != .SUCCESS {
                return false
            }
        }
        return true
    }
}

extension FireblocksManager: PollingListenerDelegate {
    func handleTransactions(transactions: [TransactionResponse]) {
        TransfersViewModel.shared.handleTransactions(transactions: transactions)
    }
    
    func lastUpdate() -> TimeInterval? {
        return TransfersViewModel.shared.lastUpdate()
    }
    
    func handleError(error: String?) {
        AppLoggerManager.shared.logger()?.log("\(error ?? "")")
    }
    
    
}

extension FireblocksManager: MessageHandlerDelegate {
    func handleOutgoingMessage(payload: String, response: @escaping (String?) -> (), error: @escaping (String?) -> ()) {
        Task {
            do {
                let res = try await SessionManager.shared.rpc(
                    deviceId: deviceId,
                    message: payload
                )
                response(res)
            } catch let err {
                error(err.localizedDescription)
            }
        }
    }
        
    private func castByteArrayToString(_ data: Any) -> String? {
        guard let data = data as? [String: Any] else {
            return nil
        }
        
        if let msg = data["message"] as? String {
            return msg.replacingOccurrences(of: "\\", with: "")
        } else {
            return nil
        }
    }
}

extension FireblocksManager: EventHandlerDelegate {
    func onEvent(event: FireblocksDev.FireblocksEvent) {
        switch event {
        case let .KeyCreation(status, error):
            AppLoggerManager.shared.logger()?.log("FireblocksManager, status(.KeyCreation): \(status.description()). Error: \(String(describing: error)).")
            break
        case let .Backup(status, error):
            AppLoggerManager.shared.logger()?.log("FireblocksManager, status(.Backup): \(status.description()). Error: \(String(describing: error)).")
            break
        case let .Recover(status, error):
            AppLoggerManager.shared.logger()?.log("FireblocksManager, status(.Recover): \(String(describing: status?.description())). Error: \(String(describing: error)).")
            break
        case let .Transaction(status, error):
            AppLoggerManager.shared.logger()?.log("FireblocksManager, status(.Transaction): \(status.description()). Error: \(String(describing: error)).")
            break
        case let .Takeover(status, error):
            AppLoggerManager.shared.logger()?.log("FireblocksManager, status(.Takeover): \(status.description()). Error: \(String(describing: error)).")
            break
        case let .JoinWallet(status, error):
            AppLoggerManager.shared.logger()?.log("FireblocksManager, status(.JoinWallet): \(status.description()). Error: \(String(describing: error)).")
            break
        @unknown default:
            AppLoggerManager.shared.logger()?.log("FireblocksManager, @unknown case")
            break
        }
    }
}
