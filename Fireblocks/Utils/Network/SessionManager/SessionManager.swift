//
//  SessionManager.swift
//  SDKDemoApp
//
//  Created by Fireblocks Ltd. on 08/03/2023.
//

import Foundation
import FireblocksSDK

struct GetDevicesResponse: Codable {
    var devices: [FireblocksDevice] = []
}

struct FireblocksDevice: Codable {
    var walletId: String?
    var deviceId: String?
    var createdAt: Int?
}

struct AssignResponse: Codable {
    var walletId: String?
}

struct JoinWalletResponse: Codable {
    var walletId: String?
}

struct MessageResponse: Codable {
    var id: Int?
    var message: String?
}

struct EstimatedFeeResponse: Codable {
    var fee: FeeResponse?
}

struct SuccessValue: Codable {
    var success: Bool?
}

struct ErrorResponse: Codable {
    var error: String
}

struct PostTransactionParams: Encodable {
    let assetId: String
    let destAddress: String
    let accountId: String = "0"
    let amount: String
    let note: String
    let feeLevel: String? //LOW, MEDIUM, HIGH
}

struct CreateTransactionResponse: Decodable {
    let id: String
    let status: TransferStatusType
}

enum SigningStatus : String, Codable {
    case SUBMITTED
    case QUEUED
    case PENDING_SIGNATURE
    case PENDING_AUTHORIZATION
    case PENDING_3RD_PARTY_MANUAL_APPROVAL
    case PENDING_3RD_PARTY
    case PENDING_CONSOLE_APPROVAL
    case SIGNED
    case SIGNED_BY_CLIENT
    case COMPLETED
    case REJECTED_BY_CLIENT
    case CANCELLED
    case FAILED
    
    init(fromRawValue: String){
        self = SigningStatus(rawValue: fromRawValue.uppercased()) ?? .SIGNED
    }
}


struct TransactionResponse: Codable, Identifiable, Hashable, Equatable {
    static func == (lhs: TransactionResponse, rhs: TransactionResponse) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    
    let id: String
    var status: TransferStatusType?
    private let createdAt: Int?
    let lastUpdated: TimeInterval?
    let details: TransactionDetails
    
    var createdSeconds: Int? {
        return createdAt != nil ? createdAt!/1000 : nil
    }
    var lastUpdatedSeconds: TimeInterval? {
        return lastUpdated != nil ? lastUpdated!/1000 : nil
    }
    
    func toTransferInfo() -> TransferInfo {
        
        var statusType: TransferStatusType = .Unknown
        if let status = details.status {
            statusType = TransferStatusType(rawValue: status.rawValue) ?? .Unknown
        }
        
        let image = AssetsImageMapper().getIconForAsset(details.assetId ?? "")
        if details.destinationAddress == nil {
            print("")
        }
        return TransferInfo(transactionID: id ,
                            creationDate: createdAt?.toDateFormattedString() ?? "",
                            lastUpdated:  lastUpdated,
                            assetId: details.assetId ?? "",
                            assetSymbol: details.assetId ?? "",
                            amount: Double(details.amountInfo?.amount ?? "0")?.formatFractions(fractionDigits: 6) ?? 0,
                            fee: details.networkFee ?? 0,
                            receiverAddress: details.destinationAddress ?? "",
                            sourceAddress: details.sourceAddress ?? "",
                            status: statusType,
                            transactionHash: details.txHash ?? " ",
                            price: Double(details.amountInfo?.amountUSD ?? "0")?.formatFractions(fractionDigits: 6) ?? 0,
                            blockChainName: details.feeCurrency ?? "",
                            senderWalletId: details.source?.walletId ?? "",
                            receiverWalletID: details.destination?.walletId ?? "",
                            image: image)
    }

}

struct TransactionDetails: Codable {
    var id: String = ""
    var note: String = ""
    var amount: Double = 0
    var source: Source?
    var destination: Destination?
    var status: TransferStatusType?
    var txHash: String?
    var assetId: String?
    var amountUSD: Double?
    var assetType: String?
    var createdAt: Int?
    var createdBy: String?
    var operation: String?
    var destinationAddress: String?
    var sourceAddress: String?
    var feeCurrency: String?
    var networkFee: Double?
    var amountInfo: AmountInfo?
    var extraParameters: ExtraParameters?
}

struct Source: Codable {
    var id: String?
    var name: String?
    var type: String?
    var subType: String?
    var walletId: String?
}

struct Destination: Codable {
    var id: String?
    var name: String?
    var type: String?
    var subType: String?
    var walletId: String?
}

struct AmountInfo: Codable {
    var amount: String?
    var amountUSD: String?
}

struct BackupInfo: Codable {
    var deviceId: String?
    var location: BackupProvider?
    var createdAt: Int?
}

struct PassphraseInfo: Codable {
    let passphraseId: String
    let location: BackupProvider
}

struct PassphraseInfoBody: Codable {
    let passphraseId: String
    let location: String
}

struct PassphraseInfos: Codable {
    let passphrases: [PassphraseInfo]
}

class SessionManager: ObservableObject {
    var isLoggedIn = false
    
    enum FBURL {
        case login
        case devices
        case assign(String)
        case joinWallet(String)
        case messages(String)
        case delete(String, String)
        case rpc(String)
        case transactions(String)
        case denyTransaction(String, String)
        case createAsset(String, String)
        case getAssets(String)
        case getSupportedAssets(String)
        case getAssetBalance(String, String)
        case getAssetAddress(String, String)
        case estimateFee(String)
        case getLatestBackupInfo(String)
        case getPassphraseInfos
        case createPassphraseInfo(PassphraseInfoBody)
        case getPassphraseInfo(String)
        
        var url: String {
            switch self {
            case .login:
                return EnvironmentConstants.baseURL + "/api/login"
            case .devices:
                return EnvironmentConstants.baseURL + "/api/devices"
            case .assign(let deviceId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/assign"
            case .joinWallet(let deviceId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/join"
            case .messages(let deviceId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/messages"
            case .delete(let deviceId, let messageId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/messages/\(messageId)"
            case .rpc(let deviceId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/rpc"
            case .transactions(let deviceId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/transactions"
            case .denyTransaction(let deviceId, let txId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/transactions/\(txId)/cancel"
            case .createAsset(let deviceId, let assetId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/accounts/0/assets/\(assetId)"
            case .getAssets(let deviceId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/accounts/0/assets/summary"
            case .getSupportedAssets(let deviceId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/accounts/0/assets/supported_assets"
            case .getAssetBalance(let deviceId, let assetId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/accounts/0/assets/\(assetId)/balance"
            case .getAssetAddress(let deviceId, let assetId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/accounts/0/assets/\(assetId)/address"
            case .estimateFee(let deviceId):
                return EnvironmentConstants.baseURL + "/api/devices/\(deviceId)/transactions"
            case .getLatestBackupInfo(let walletId):
                return EnvironmentConstants.baseURL + "/api/wallets/\(walletId)/backup/latest"
            case .getPassphraseInfos:
                return EnvironmentConstants.baseURL + "/api/passphrase"
            case .createPassphraseInfo(let passphraseInfo):
                return EnvironmentConstants.baseURL + "/api/passphrase/\(passphraseInfo.passphraseId)"
            case .getPassphraseInfo(let passphraseId):
                return EnvironmentConstants.baseURL + "/api/passphrase/\(passphraseId)"
            }
        }
        
        var timeout: TimeInterval? {
            switch self {
            case .login:
                return 30.0
            case .devices:
                return 30.0
            case .assign(_):
                return 30.0
            case .joinWallet(_):
                return 30.0
            case .messages(_):
                return 30.0
            case .delete(_, _):
                return 30.0
            case .rpc(_):
                return 30.0
            case .transactions(_):
                return 30.0
            case.denyTransaction(_, _):
                return 30.0
            case.createAsset(_, _):
                return 30.0
            case.getAssets(_):
                return 30.0
            case.getSupportedAssets(_):
                return 30.0
            case .estimateFee(_):
                return 30.0
            case .getAssetBalance(_, _):
                return 30.0
            case .getAssetAddress(_, _):
                return 30.0
            case .getLatestBackupInfo(_):
                return 30.0
            case .getPassphraseInfos:
                return 30.0
            case .createPassphraseInfo(_):
                return 30.0
            case .getPassphraseInfo(_):
                return 30.0
            }
        }
    }
    
    static let shared = SessionManager()
    
    private init() {}
    
    func sendRequest(url: URL, httpMethod: String = "POST", timeout: TimeInterval? = nil, numberOfRetries: Int = 2, message: String? = nil, body: Any? = nil, skipLogs: Bool = false) async throws -> (Data) {
        let currentAccessToken: String = await AuthRepository.getUserIdToken()
        var request = URLRequest(url: url)
        request.setValue(
            "Bearer \(currentAccessToken)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpMethod = httpMethod
        if let timeout = timeout {
            request.timeoutInterval = timeout
        }
        
        if httpMethod != "GET" {
            var body = body
            if let message {
                body = ["message": message]
            }
            if let body {
                let bodyData = try? JSONSerialization.data(
                    withJSONObject: body,
                    options: []
                )
                request.httpBody = bodyData
            }
        }
        
        let session = URLSession.shared
        AppLoggerManager.shared.logger()?.log("\n📣📣📣📣\nSessionManager send request:\n\(request)\n📣📣📣📣")
        do {
            AppLoggerManager.shared.logger()?.log("SessionManager REQUEST: \(String(describing: request))")
            print("SessionManager REQUEST: \(String(describing: request))")
            let (data, response) = try await session.data(for: request)
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if statusCode >= 200, statusCode <= 299 {
                    print("SessionManager RESPONSE: \(url)\n\(String(describing: String(data: data, encoding: .utf8)))")
                    if !skipLogs {
                        AppLoggerManager.shared.logger()?.log("SessionManager RESPONSE: \(String(describing: String(data: data, encoding: .utf8)))")
                    }
                    return data
                } else {
                    print("SessionManager RESPONSE STATUS: \(statusCode) \(url)\n\(String(describing: String(data: data, encoding: .utf8)))")

                    return try await retry(url: url, httpMethod: httpMethod, timeout: timeout, numberOfRetries: numberOfRetries, message: message, body: body, skipLogs: skipLogs, error: SessionManager.appError(code: statusCode))
                }
            } else {
                return try await retry(url: url, httpMethod: httpMethod, timeout: timeout, numberOfRetries: numberOfRetries, message: message, body: body, skipLogs: skipLogs, error: SessionManager.error)
            }
        } catch {
            print("SessionManager Error: \(error)")
            return try await retry(url: url, httpMethod: httpMethod, timeout: timeout, numberOfRetries: numberOfRetries, message: message, body: body, skipLogs: skipLogs, error: error as NSError)
        }
    }
    
    private func retry(url: URL, httpMethod: String, timeout: TimeInterval?, numberOfRetries: Int, message: String?, body: Any?, skipLogs: Bool, error: NSError) async throws -> (Data) {
        if numberOfRetries <= 0 {
            throw SessionManager.error
        } else {
            print("Retry \(url.absoluteString) - \(numberOfRetries) more retries")
            AppLoggerManager.shared.logger()?.log("Retry \(url.absoluteString) - \(numberOfRetries) more retries. Error: \(error.localizedDescription)")
            return try await self.sendRequest(url: url, httpMethod: httpMethod, timeout: timeout, numberOfRetries: numberOfRetries - 1, message: message, body: body, skipLogs: skipLogs)
        }
    }
}

extension SessionManager {
    static let error = NSError(domain: "Networking", code: 0, userInfo: [NSLocalizedDescriptionKey : "Networking Error"])
    static func appError(code: Int) -> NSError {
        return NSError(domain: "Networking", code: code, userInfo: [NSLocalizedDescriptionKey : "Networking Error"])
    }
    
    func login() async throws -> String? {
        if let url = URL(string: FBURL.login.url) {
            return String(data: try await sendRequest(url: url, numberOfRetries: 5), encoding: .utf8)
        } else {
            throw SessionManager.error
        }
    }

    func getDevices() async throws -> GetDevicesResponse? {
        if let url = URL(string: FBURL.devices.url) {
            let data = try await sendRequest(url: url, httpMethod: "GET", numberOfRetries: 5)
            let value = try JSONDecoder().decode(GetDevicesResponse.self, from: data)
            return value
        } else {
            throw SessionManager.error
        }
    }

    func assign(deviceId: String) async throws -> AssignResponse {
        if let url = URL(string: FBURL.assign(deviceId).url) {
            let data = try await sendRequest(url: url, numberOfRetries: 5)
            let value = try JSONDecoder().decode(AssignResponse.self, from: data)
            return value
        } else {
            throw SessionManager.error
        }
    }

    func joinWallet(deviceId: String, walletId: String) async throws -> JoinWalletResponse {
        let body = ["walletId": walletId]
        if let url = URL(string: FBURL.joinWallet(deviceId).url) {
            let data = try await sendRequest(url: url, numberOfRetries: 5, body: body)
            let value = try JSONDecoder().decode(JoinWalletResponse.self, from: data)
            return value
        } else {
            throw SessionManager.error
        }
    }

    func getMessages(deviceId: String) async throws -> [MessageResponse] {
        if let url = URL(string: FBURL.messages(deviceId).url) {
            var components = URLComponents(string: url.absoluteString)
            components?.queryItems = []
            components?.queryItems?.append(
                URLQueryItem(name: "physicalDeviceId", value: Fireblocks.getPhysicalDeviceId())
                )

            if let fullString = components?.string, let fullURL = URL(string: fullString) {
                let data = try await sendRequest(url: fullURL, httpMethod: "GET", timeout: FBURL.messages(deviceId).timeout, numberOfRetries: 0)
                return try JSONDecoder().decode([MessageResponse].self, from: data)
            } else {
                throw SessionManager.error
            }
        } else {
            throw SessionManager.error
        }
    }
    
    func deleteMessage(deviceId: String, messageId: String) async {
        do {
            if let url = URL(string: FBURL.delete(deviceId, messageId).url) {
                let response = try await sendRequest(url: url, httpMethod: "DELETE", timeout: FBURL.delete(deviceId, messageId).timeout, numberOfRetries: 0)
                print("DELETED: \(messageId)")
            }
        } catch {
            print("DELETED ERROR: \(error.localizedDescription)")
        }
    }


    func rpc(deviceId: String, message: String) async throws -> String? {
        print("RPC: \(message)")
        if let url = URL(string: FBURL.rpc(deviceId).url) {
            let str = String(data: try await sendRequest(url: url, timeout: FBURL.rpc(deviceId).timeout, message: message, skipLogs: true), encoding: .utf8)
            print(str ?? "", message, url)
            return str
        } else {
            throw SessionManager.error
        }
    }
    
    func createTransaction(deviceId: String, body: Any) async throws -> CreateTransactionResponse? {
        if let url = URL(string: FBURL.transactions(deviceId).url) {
            let data = try await sendRequest(url: url, httpMethod: "POST", timeout: FBURL.transactions( deviceId).timeout, numberOfRetries: 0, body: body)
            let response: CreateTransactionResponse? = try JSONDecoder().decode(CreateTransactionResponse.self, from: data)
            return response
        } else {
            throw SessionManager.error
        }
    }

    func getTransactions(deviceId: String, details: Bool = true, startDate: TimeInterval?) async throws -> [TransactionResponse]? {
        if let url = URL(string: FBURL.transactions(deviceId).url) {
            var components = URLComponents(string: url.absoluteString)
            components?.queryItems = []
            if details {
                components?.queryItems?.append(
                    URLQueryItem(name: "details", value: "true")
                )
            }
            
            if let startDate {
                components?.queryItems?.append(
                    URLQueryItem(name: "startDate", value: "\(startDate)")
                )
            }
            components?.queryItems?.append(
                URLQueryItem(name: "poll", value: "true")
            )

            if let fullString = components?.string, let fullURL = URL(string: fullString) {
                print(fullURL)
                let data = try await sendRequest(url: fullURL, httpMethod: "GET", timeout: FBURL.transactions( deviceId).timeout, numberOfRetries: 0)
                let transactions: [TransactionResponse] = try JSONDecoder().decode([TransactionResponse].self, from: data)
                return transactions
            }
            return nil
        } else {
            throw SessionManager.error
        }

    }

    func createAsset(deviceId: String, assetId: String) async throws -> String? {
        if let url = URL(string: FBURL.createAsset(deviceId, assetId).url) {
            let data = try await sendRequest(url: url, httpMethod: "POST", timeout: FBURL.createAsset(deviceId, assetId).timeout, numberOfRetries: 0)
            return String(data: data, encoding: .utf8)
        } else {
            throw SessionManager.error
        }
    }

    func getAssets(deviceId: String) async throws -> [String: AssetSummary] {
        if let url = URL(string: FBURL.getAssets(deviceId).url) {
            let data = try await sendRequest(url: url, httpMethod: "GET", timeout: FBURL.getAssets(deviceId).timeout, numberOfRetries: 0)
            let assets: [String: AssetSummary] = try JSONDecoder().decode([String: AssetSummary].self, from: data)
            return assets
        } else {
            throw SessionManager.error
        }
    }

    func getSupportedAssets(deviceId: String) async throws -> [Asset] {
        if let url = URL(string: FBURL.getSupportedAssets(deviceId).url) {
            let data = try await sendRequest(url: url, httpMethod: "GET", timeout: FBURL.getAssets(deviceId).timeout, numberOfRetries: 0)
            let assets: [Asset] = try JSONDecoder().decode([Asset].self, from: data)
            return assets
        } else {
            throw SessionManager.error
        }
    }

    func getAssetBalance(deviceId: String, assetId: String) async throws -> AssetBalance {
        if let url = URL(string: FBURL.getAssetBalance(deviceId, assetId).url) {
            let data = try await sendRequest(url: url, httpMethod: "GET", timeout: FBURL.getAssetBalance(deviceId, assetId).timeout, numberOfRetries: 0)
            let balance: AssetBalance = try JSONDecoder().decode(AssetBalance.self, from: data)
            return balance
        } else {
            throw SessionManager.error
        }
    }

    func getAssetAddress(deviceId: String, assetId: String) async throws -> AssetAddress {
        if let url = URL(string: FBURL.getAssetAddress(deviceId, assetId).url) {
            let data = try await sendRequest(url: url, httpMethod: "GET", timeout: FBURL.getAssetAddress(deviceId, assetId).timeout, numberOfRetries: 0)
            let address: AssetAddress = try JSONDecoder().decode(AssetAddress.self, from: data)
            return address
        } else {
            throw SessionManager.error
        }
    }

    func estimateFee(deviceId: String, body: Any) async throws -> EstimatedFeeResponse? {
        if let url = URL(string: FBURL.estimateFee(deviceId).url) {
            let data = try await sendRequest(url: url, httpMethod: "POST", timeout: FBURL.estimateFee( deviceId).timeout, numberOfRetries: 0, body: body)
            let fee: EstimatedFeeResponse? = try JSONDecoder().decode(EstimatedFeeResponse.self, from: data)
            return fee
        } else {
            throw SessionManager.error
        }
    }

    func denyTransaction(deviceId: String, txId: String) async throws -> Bool {
        if let url = URL(string: FBURL.denyTransaction(deviceId, txId).url) {
            let data = try await sendRequest(url: url, httpMethod: "POST", timeout: FBURL.denyTransaction(deviceId, txId).timeout, numberOfRetries: 0)
            let success: SuccessValue = try JSONDecoder().decode(SuccessValue.self, from: data)
            return success.success ?? false
        } else {
            throw SessionManager.error
        }
    }

    func getLatestBackupInfo(walletId: String) async throws -> BackupInfo {
        if let url = URL(string: FBURL.getLatestBackupInfo(walletId).url) {
            let data = try await sendRequest(url: url, httpMethod: "GET", timeout: FBURL.getLatestBackupInfo(walletId).timeout, numberOfRetries: 0)
            let info: BackupInfo = try JSONDecoder().decode(BackupInfo.self, from: data)
            return info
        } else {
            throw SessionManager.error
        }
    }
    
    func getPassphraseInfos() async throws -> PassphraseInfos {
        if let url = URL(string: FBURL.getPassphraseInfos.url) {
            let data = try await sendRequest(url: url, httpMethod: "GET", timeout: FBURL.getPassphraseInfos.timeout, numberOfRetries: 0)
            let info: PassphraseInfos = try JSONDecoder().decode(PassphraseInfos.self, from: data)
            return info
        } else {
            throw SessionManager.error
        }
    }
    
    func createPassphraseInfo(passphraseInfo: PassphraseInfoBody) async throws {
        if let url = URL(string: FBURL.createPassphraseInfo(passphraseInfo).url) {
            let _ = try await sendRequest(url: url, httpMethod: "POST", timeout: FBURL.createPassphraseInfo(passphraseInfo).timeout, numberOfRetries: 0, body: passphraseInfo.dictionary())
        } else {
            throw SessionManager.error
        }
    }

    func getPassphraseInfo(passphraseId: String) async throws -> PassphraseInfo {
        if let url = URL(string: FBURL.getPassphraseInfo(passphraseId).url) {
            let data = try await sendRequest(url: url, httpMethod: "GET", timeout: FBURL.getPassphraseInfo(passphraseId).timeout, numberOfRetries: 0)
            let info: PassphraseInfo = try JSONDecoder().decode(PassphraseInfo.self, from: data)
            return info
        } else {
            throw SessionManager.error
        }
    }
    

}
