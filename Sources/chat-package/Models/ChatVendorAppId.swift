//
//  ChatVendorAppId.swift
//  ChatHTTPLoader
//
//  Created by Mendy Edri on 30/10/2019.
//  Copyright © 2019 CWT. All rights reserved.
//

import Foundation

/** Data response model for mapping STS-metadata response */

public struct ChatVendorAppId: Codable, Equatable {
    
    public var responseHeader: ResponseHeader
    public var meta: ResponseMetadata
    
    // The only one actually in use :|
    public var appId: String
    
    enum CodingKeys: String, CodingKey {
        case responseHeader
        case meta = "responseMeta"
        case appId
    }
}
