//
//  SpotifyAuthManager.swift
//  ThreeDCoverFlow
//
//  Created by Michael Rosas Ceronio on 4/23/25.
//

import Foundation
import UIKit

class SpotifyAuthManager {
    static let shared = SpotifyAuthManager()

    private let clientID = "9ab38df44e60464fbfc5589cf5115a03"
    private let redirectURI = "myapp://callback"
    private let scopes = "user-read-playback-state user-modify-playback-state user-read-currently-playing"

    private var codeVerifier = ""

    func startSpotifyLogin() {
        codeVerifier = PKCEManager.shared.generateCodeVerifier()
        let codeChallenge = PKCEManager.shared.generateCodeChallenge(from: codeVerifier)
        let authURL = "https://accounts.spotify.com/authorize?" +
        "client_id=\(clientID)&" +
        "response_type=code&" +
        "redirect_uri=\(redirectURI)&" +
        "scope=\(scopes)&" +
        "code_challenge_method=S256&" +
        "code_challenge=\(codeChallenge)"

        if let url = URL(string: authURL) {
            UIApplication.shared.open(url)
        }
    }

    func exchangeCodeForToken(code: String) {
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "client_id": clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": codeVerifier
        ]

        let bodyString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                print("❌ Failed to exchange code for token")
                return
            }
            
            UserDefaults.standard.set(accessToken, forKey: "access_token")

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("SpotifyAuthorized"), object: nil)
            }


            print("✅ Access token: \(accessToken)")
            UserDefaults.standard.set(accessToken, forKey: "access_token")
        }.resume()
    }
}
