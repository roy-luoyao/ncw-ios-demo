//
//  DeriveKeysViewModel.swift
//  NCW-sandbox
//
//  Created by Dudi Shani-Gabay on 06/03/2024.
//

import Foundation
import UIKit
import FireblocksSDK

extension DeriveKeysView {
    
    class ViewModel: ObservableObject {
        let privateKeys: Set<FullKey>
        @Published var selectedAsset: Asset?
        @Published var copiedText: String?
        @Published var items: [String: [DerivedKeyItem]] = [:]
        
        var title: String = "Copy the Private Keys and save them in a secure location. You are now the responsible for their security."
        var navigationBarTitle: String = LocalizableStrings.exportPrivateKeyTitle
        
        init(privateKeys: Set<FullKey>) {
            self.privateKeys = privateKeys
            privateKeys.forEach { key in
                if let algorithm = key.algorithm, let privateKey = key.privateKey {
                    self.items[algorithm.rawValue] = AssetListViewModel.shared.getAssetSummary().filter({$0.asset?.algorithm == algorithm.rawValue}).map({DerivedKeyItem(assetSummary: $0, algorithm: algorithm.rawValue, privateKey: privateKey)})
                }
            }
            Task {
                await generateKeys()
            }
        }
        
        func sortedPrivateKeys() -> [FullKey] {
            return privateKeys.filter({$0.algorithm != nil}).sorted(by: {$0.algorithm!.rawValue > $1.algorithm!.rawValue})
        }
        
        func getKeysTitle(algorithm: String) -> String {
            if algorithm == Algorithm.MPC_ECDSA_SECP256K1.rawValue {
                return "XPRV"
            }
            if algorithm == Algorithm.MPC_EDDSA_ED25519.rawValue {
                return "FPRV"
            }
            return ""
        }
        
        func generateKeys() async {
            for (key, value) in items {
                for i in 0..<value.count {
                    if let privateKey = items[key]?[i].privateKey {
                        let data = await items[key]?[i].deriveAssetKey(privateKey: privateKey)
                        let wif = items[key]?[i].getWif(privateKey: data?.data)
                        DispatchQueue.main.async {
                            self.items[key]?[i].keyData = data
                            self.items[key]?[i].wif = wif
                        }
                    }
                }
            }
        }
    }
    
}
