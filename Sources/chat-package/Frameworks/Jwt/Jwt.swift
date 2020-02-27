//
//  Jwt.swift
//  Jwt
//
//  Created by Mendy Edri on 29/10/2019.
//  Copyright © 2019 CWT. All rights reserved.
//

import Foundation

/** Modular Jwt, suitable for myCWT needs */

public protocol Jwtable {
    func isJwtExp() throws -> Bool
    var jwtString: String { get set }
    var parser: JwtParserable { get }
    func value(for key: String) -> String?
}

public struct Jwt: Jwtable {
    
    public enum Error: Swift.Error {
        case invalid
    }
        
    public var jwtString: String {
        didSet {
            parser.jwt(self.jwtString)
        }
    }
    
    public var parser: JwtParserable
    
    public init() {
        parser = JwtDefaultParser(jwt: "")
        self = Jwt(string: "", parser: parser)
    }
    
    public init(string: String, parser: JwtParserable) {
        self.jwtString = string
        
        self.parser = parser
        self.parser.jwt(jwtString)
    }
    
    public func value(for key: String) -> String? {
        return parser.value(for: key) as? String
    }
    
    // MARK: Jwtable Implementation
    
    public func isJwtExp() throws -> Bool {
        guard let experation = parser.value(for: CommonKeys.experation.rawValue) as? Double else {
            throw Error.invalid
        }
        let now = Date().timeIntervalSince1970
        return experation <= now
    }
}

extension Jwt {
    enum CommonKeys: String {
        case experation = "exp"
        case userId = "userId"
        case pingId = "id"
    }
}
