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
        let privateKeys: [String]
        @Published var selectedAsset: Asset?
        @Published var items: [String: [DerivedKeyItem]] = [:]
        
        var title: String = "Copy the Private Keys and save them in a secure location. You are now the responsible for their security."
        var navigationBarTitle: String = LocalizableStrings.exportPrivateKeyTitle
        
        init(privateKeys: [String]) {
            self.privateKeys = privateKeys
            privateKeys.forEach { key in
                self.items[key] = AssetListViewModel.shared.getAssetSummary().map({DerivedKeyItem(assetSummary: $0)})
            }
            Task {
                await generateKeys()
            }
        }
        
        func generateKeys() async {
            for (key, value) in items {
                for i in 0..<value.count {
                    let data = await items[key]?[i].deriveAssetKey(privateKey: key)
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
