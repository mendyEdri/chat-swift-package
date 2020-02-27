//
//  ResponseMetadata.swift
//  ChatHTTPLoader
//
//  Created by Mendy Edri on 05/11/2019.
//  Copyright © 2019 CWT. All rights reserved.
//

import Foundation

/** Data response model  for mapping STS and STS-metadata response metadata object */

public struct ResponseMetadata: Codable, Equatable {
    public var trxId: String
    public var reqId: String
    public var status: String
}
