//
//  Environment.swift
//  Fireblocks
//
//  Created by Fireblocks Ltd. on 04/07/2023.
//

import Foundation
import FireblocksSDK

struct EnvironmentConstants {
//    static let baseURL = "https://api-sb-1.ncw-demo.com"
    static let baseURL = "http://34.140.158.109:3000"
    static let env: FireblocksSDK.FireblocksEnvironment = .sandbox
}

extension Bundle {
    var releaseVersionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    var buildVersionNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    
    var versionLabel: String {
        return "Version " + releaseVersionNumber + " • " + "Build " + buildVersionNumber + " • " + EnvironmentConstants.env.rawValue.capitalized
    }
}


