//
//  FlickrOAuth.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 18/6/18.
//  Copyright © 2018 S&J. All rights reserved.
//

import Foundation

final class FlickrOAuth {
    let ApiKey = "d385ff977003a2f2586eee316d1391c4"
    let Secret = "1c15c8c8dbbd56a5"
    let Url = "https://www.flickr.com/services/oauth/request_token"
    
    var OAuthInfo: [String: String]
    var ReqToGetToken: String?
    var Token: String?
    var TokenSecret: String?
    
    private init() {
        OAuthInfo = [
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_version": "1.0",
            //"oauth_callback": "http%3A%2F%2Fwww.wackylabs.net%2Foauth%2Ftest",
            "oauth_callback": "",
            "oauth_signature": "",
            "oauth_nonce": "C2F26CD5C075BA9050AD8EE90644CF29",
            "oauth_timestamp": "",
            "oauth_consumer_key": "768fe946d252b119746fda82e1599980"
        ]
    }
    
    static let shared = FlickrOAuth()
    
    func CreateOauthString() {
        let timeStamp = Int64(Date.timeIntervalSinceReferenceDate) //1316657628
        let timeStampHash = md5(String(timeStamp)).uppercased()
        OAuthInfo["oauth_nonce"] = timeStampHash
        OAuthInfo["oauth_timestamp"] = String(timeStamp)
        let hashKey = "\(Secret)&"
        let allowedSet = CharacterSet.alphanumerics.union([".", "_", "~", "-"])
        let simpleAllowedSet = CharacterSet.alphanumerics.union([".", "_", "~", "-", "=", "&", "%"])

        let part1 = "GET"
        let part2 = "\(Url)"
        let part3 = "oauth_callback=\(String(describing: OAuthInfo["oauth_callback"]!))&oauth_consumer_key=\(ApiKey)&oauth_nonce=\(OAuthInfo["oauth_nonce"]!)&oauth_signature_method=\(String(describing: OAuthInfo["oauth_signature_method"]!))&oauth_timestamp=\(timeStamp)&oauth_version=\(String(describing: OAuthInfo["oauth_version"]!))"
        
        let escapedPart1 = part1.addingPercentEncoding(withAllowedCharacters: allowedSet)!
        let escapedPart2 = part2.addingPercentEncoding(withAllowedCharacters: allowedSet)!
        let escapedPart3 = part3.addingPercentEncoding(withAllowedCharacters: allowedSet)!
        let simpleEscapedPart3 = part3.addingPercentEncoding(withAllowedCharacters: simpleAllowedSet)!
        let escapedString = "\(escapedPart1)&\(escapedPart2)&\(escapedPart3)"
        
        OAuthInfo["oauth_signature"] = escapedString.hmac(algorithm: .SHA1, key: hashKey)

        let escapedSignature = OAuthInfo["oauth_signature"]!.addingPercentEncoding(withAllowedCharacters: allowedSet)!
        let oauthString  = "\(part2)?\(simpleEscapedPart3)&oauth_signature=\(escapedSignature)"
        
        ReqToGetToken = oauthString
    }
    
    func md5(_ string: String) -> String {
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating:0, count:Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Init(context)
        CC_MD5_Update(context, string, CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate()
        var hexString = ""
        for byte in digest {
            hexString += String(format:"%02x", byte)
        }
        return hexString
    }
    
    func GetTokenRequest(_ completionHandler: @escaping (_ token: String?, _ secret: String?, _ error: Error?, _ other: Int) -> Void) {
        var request = URLRequest(url: URL(string: ReqToGetToken!)!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                completionHandler(nil, nil, error, 0)
            }
            let str = String.init(data: data!, encoding: .utf8)
            let pairs = str?.split(separator: "&")
            var parsedResult = [String: String]()
            for pair in pairs! {
                let key: String = String(pair.split(separator: "=")[0])
                let value: String = String(pair.split(separator: "=")[1])
                parsedResult[key] = value
            }
            if let token = parsedResult["oauth_token"], let secret = parsedResult["oauth_token_secret"] {
                completionHandler(token, secret, nil, 0)
            }
        }
        task.resume()
    }
    
    func GetToken() -> Void {
        GetTokenRequest{ (token, secret, error, other) in
            if error != nil {
                return
            } else if other == -1 {
                return
            } else {
                self.Token = token
                self.TokenSecret = secret
            }
        }
    }
    
}

enum HMACAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    func toCCHmacAlgorithm() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:
            result = kCCHmacAlgMD5
        case .SHA1:
            result = kCCHmacAlgSHA1
        case .SHA224:
            result = kCCHmacAlgSHA224
        case .SHA256:
            result = kCCHmacAlgSHA256
        case .SHA384:
            result = kCCHmacAlgSHA384
        case .SHA512:
            result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    func hmac(algorithm: HMACAlgorithm, key: String) -> String {
        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = self.cString(using: String.Encoding.utf8)
        var result = [CUnsignedChar](repeating: 0, count: Int(algorithm.digestLength()))
        CCHmac(algorithm.toCCHmacAlgorithm(), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
        let hmacData:NSData = NSData(bytes: result, length: (Int(algorithm.digestLength())))
        let hmacBase64 = hmacData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength76Characters)
        return String(hmacBase64)
    }
}

