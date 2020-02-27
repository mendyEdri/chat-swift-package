//
//  ChatVendorToken.swift
//  ChatHTTPLoader
//
//  Created by Mendy Edri on 03/11/2019.
//  Copyright © 2019 CWT. All rights reserved.
//

import Foundation

/** Data response model for mapping STS response */
public struct ChatVendorToken: Equatable, Codable {
    
    public var header: ResponseHeader
    public var tokenType: String
    public var accessToken: String
    public var expiration: TimeInterval
    public var cwtToken: String
    public var metadata: ResponseMetadata
    
    enum CodingKeys: String, CodingKey {
        case header = "responseHeader"
        case tokenType = "token_type"
        case accessToken = "access_token"
        case expiration = "expires_in"
        case cwtToken = "cwtToken"
        case metadata = "responseMeta"
    }
}
