//
//  AssetModel.swift
//  Fireblocks
//
//  Created by Fireblocks Ltd. on 20/06/2023.
//

import Foundation
import UIKit.UIImage

struct AssetSummary: Codable, Identifiable, Hashable {
    var asset: Asset?
    var address: AssetAddress?
    var balance: AssetBalance?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var id: String {
        return asset?.id ?? ""
    }
}

struct Asset: Codable, Identifiable, Hashable {
    static func == (lhs: Asset, rhs: Asset) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }

    
    var id: String = ""
    var symbol: String = ""
    var name: String
    var decimals: Int = 0
    var testnet = false
    var hasFee = false
    let type: String
    var deprecated = false
    var coinType: Int?
    var blockchain = ""
    var ethNetwork: String?
    var networkProtocol = ""
    var baseAsset = ""
    var rate: Double? = 1.0
    var fee: FeeResponse?
    var balance: Double?
    var price: Double?
    var address: String?
    var iconUrl: String?
    
    var image: UIImage {
        let assetImage = AssetsImageMapper().getIconForAsset(id)
        return assetImage
    }
    
}

struct AssetBalance: Codable, Hashable {
    var id: String
    var total: String = "0"
    var frozen: String = "0"
    var locked: String = "0"
    var pending: String = "0"
    var staked: String = "0"
    var reserved: String = "0"
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

struct AssetAddress: Codable, Hashable {
    var address: String
    var accountId: String?
    var accountName: String?
    var addressType: String?
    var addressIndex: Int?

    func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }

}
