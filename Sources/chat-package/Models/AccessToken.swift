//
//  AccessToken.swift
//  ChatProject
//
//  Created by Mendy Edri on 29/01/2020.
//  Copyright © 2020 CWT. All rights reserved.
//

import Foundation

public struct AccessToken: Codable {
    public var accessToken: String
    public var refreshToken: String
    public var type: String
    public var expiration: TimeInterval
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case type = "token_type"
        case expiration = "expires_in"
    }
}
