//
//  IdentityStoreInfo.swift
//  ChatProject
//
//  Created by Mendy Edri on 16/02/2020.
//  Copyright © 2020 CWT. All rights reserved.
//

import Foundation

public struct IdentityMetadata: Codable {
    public let type: String
    public let travelerGUID: String
    public let externalID: String
    
    public init(type: String, travelerGUID: String, externalID: String) {
        self.type = type
        self.travelerGUID = travelerGUID
        self.externalID = externalID
    }
}

public struct IdentityInfo: Codable {
    let topId: String
    let subId: String
    let userId: String
    let clientType: String = "iOS"
    let metadata: IdentityMetadata
    
    public init(topId: String, subId: String, userId: String, metadata: IdentityMetadata) {
        self.topId = topId
        self.subId = subId
        self.userId = userId
        self.metadata = metadata
    }
}
