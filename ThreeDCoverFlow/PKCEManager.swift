//
//  PCKEManager.swift
//  ThreeDCoverFlow
//
//  Created by Michael Rosas Ceronio on 4/23/25.
//

import Foundation
import CommonCrypto

class PKCEManager {
    static let shared = PKCEManager()

    private init() {}

    func generateCodeVerifier() -> String {
        let length = 64
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }

    func generateCodeChallenge(from codeVerifier: String) -> String {
        guard let data = codeVerifier.data(using: .utf8) else { return "" }

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }

        let hashData = Data(hash)
        let base64 = hashData.base64EncodedString()

        // Remove padding, replace + and / with URL-safe chars
        let challenge = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return challenge
    }
}
