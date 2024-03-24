//
//  DerivedKeyItem.swift
//  NCW-sandbox
//
//  Created by Dudi Shani-Gabay on 07/03/2024.
//

import Foundation
import FireblocksDev
import CommonCrypto

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            let bytes = hexString[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }

    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}

extension Data {
    static let base58Alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

    func base58EncodedString() -> String {
        var bytes = [UInt8](self)
        var zerosCount = 0
        var length = 0
        
        for b in bytes {
            if b != 0 { break }
            zerosCount += 1
        }
        
        bytes.removeFirst(zerosCount)
        
        let size = bytes.count * 138 / 100 + 1
        
        var base58: [UInt8] = Array(repeating: 0, count: size)
        for b in bytes {
            var carry = Int(b)
            var i = 0
            
            for j in 0...base58.count-1 where carry != 0 || i < length {
                carry += 256 * Int(base58[base58.count - j - 1])
                base58[base58.count - j - 1] = UInt8(carry % 58)
                carry /= 58
                i += 1
            }
            
            assert(carry == 0)
            
            length = i
        }
        
        var zerosToRemove = 0
        var str = ""
        for b in base58 {
            if b != 0 { break }
            zerosToRemove += 1
        }
        base58.removeFirst(zerosToRemove)
        
        while 0 < zerosCount {
            str = "\(str)1"
            zerosCount -= 1
        }
        
        for b in base58 {
            str = "\(str)\(Data.base58Alphabet[String.Index(encodedOffset: Int(b))])"
        }
        
        return str
    }
}

struct DerivedKeyItem {
    let assetSummary: AssetSummary
    var isExposed: Bool = false
    var isWifExposed: Bool = false
    var keyData: KeyData?
    var wif: String?

    func deriveAssetKey(privateKey: String) async -> KeyData?{
        let derivationParams =  DerivationParams(
            coinType: assetSummary.asset?.coinType ?? 0,
            account: Int(assetSummary.address?.accountId ?? "0") ?? 0,
            change: 0,
            index: assetSummary.address?.addressIndex ?? 0)
        
        return await FireblocksManager.shared.deriveAssetKey(privateKey: privateKey, derivationParams: derivationParams)

    }
    
    func getWif(privateKey: String?, isMainNet: Bool = false) -> String? {
        var wif: String?
        if let privateKey {
            if let networkProtocol = assetSummary.asset?.networkProtocol{
                if (networkProtocol.contains("BTC")) {
                    let prefix = !isMainNet ? "ef" : "80"
                    let suffix = "01"
                    let extendedKey = prefix + privateKey + suffix
                    
                    guard let extendedKeyData = Data(hexString: extendedKey) else {
                        return "Invalid private key format"
                    }
                    
                    let sha256Pass1 = extendedKeyData.sha256()
                    let sha256Pass2 = sha256Pass1.sha256()
                    let checksum = sha256Pass2.prefix(4)
                    
                    let finalKeyData = extendedKeyData + checksum
                    
                    wif = finalKeyData.base58EncodedString()
                    if let wif {
                        return "p2wpkh:\(wif)"
                    }
                }
            }
        }
        return wif
    }

}
