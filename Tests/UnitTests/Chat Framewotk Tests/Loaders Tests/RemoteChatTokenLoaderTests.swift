//
//  RemoteChatTokenLoaderTests.swift
//  ChatHTTPLoaderTests
//
//  Created by Mendy Edri on 05/11/2019.
//  Copyright © 2019 CWT. All rights reserved.
//

import XCTest
import lit_networking
@testable import ChatClient

class RemoteChatTokenLoaderTests: XCTestCase {
    
    func test_apiChatTokenLoader_emptyURL() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.requestedURLs, [])
    }
    
    func test_apiChatTokenLoader_authFailed() {
        let (sut, client) = makeSUT()
        
        let authFailedJSON = authFailedResponseJSON()
        
        expect(that: sut, be: .failure(.authFailed), when: {
            client.complete(withSatus: 401, data: authFailedJSON)
        })
    }
    
    func test_apiChatTokenLoader_authTokenUnknownVendor() {
        let (sut, client) = makeSUT()
        
        let unknownVendorJSON = unknownVendorResponseJSON()
        
        expect(that: sut, be: .failure(.unknownVendor), when: {
            client.complete(withSatus: 404, data: unknownVendorJSON)
        })
    }
    
    func test_apiChatTokenLoader_successJSONWithBadStatusCode() {
        
        let randomNotOKStatusCodes = [201, 99, 402, 400, 300, 190]
        let itemData = createSuccessJson()
        
        randomNotOKStatusCodes.forEach { code in
            
            let (sut, client) = makeSUT()
            expect(that: sut, be: .failure(.invalidData), when: {
                client.complete(withSatus: code, data: itemData)
            })
        }
    }
    
    func test_apiChatTokenLoader_badJSONWithGoodStatusCode() {
        let (sut, client) = makeSUT()
        let authFailedJSON = authFailedResponseJSON()
        
        expect(that: sut, be: .failure(.invalidData), when: {
            client.complete(withSatus: 200, data: authFailedJSON)
        })
    }
    
    func test_apiChatTokenLoader_successJson() {
        let (sut, client) = makeSUT()
        
        let item = createVendorTokenItem()
        let successJSON = createJsonItem(from: item)
        
        expect(that: sut, be: .success(item), when: {
            client.complete(withSatus: 200, data: successJSON)
        })
    }
    
    func test_apiChatTokenLoader_invalidData() {
        let (sut, client) = makeSUT()
        
        expect(that: sut, be: .failure(.invalidData), when: {
            client.complete(withSatus: 200, data: Data("invalid data, but not a nil".utf8))
        })
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> (RemoteClientTokenLoader, HTTPClientMock) {
        let client = HTTPClientMock()
        let url = URL(string: "https://a-url.com")!
        let sut = RemoteClientTokenLoader(url: url, client: client)
        
        return (sut, client)
    }
    
    private func expect(that sut: RemoteClientTokenLoader, be result: RemoteClientTokenLoader.Result, when action: @escaping () -> Void,  file: StaticString = #file, line: UInt = #line) {
        
        var capturedResult = [RemoteClientTokenLoader.Result]()
        
        sut.load(with: AccessTokenMockAdapter()) { capturedResult.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResult, [result], file: file, line: line)
    }
}

extension RemoteChatTokenLoaderTests {
    private func createSuccessJson() -> Data {
        let item = createVendorTokenItem()
        return createJsonItem(from: item)
    }
    
    private func createJsonItem(from item: ChatVendorToken) -> Data {
        return try! JSONEncoder().encode(item)
    }
    
    private func createVendorTokenItem() -> ChatVendorToken {
        let (header, meta) = BuilderHelper().buildSuccessHeaderAndMeta()
        let type = "Bearer"
        
        return ChatVendorToken(header: header, tokenType: type, accessToken: accessToken(), expiration: fourHoursExpiration(), cwtToken: cwtToken(), metadata: meta)
    }
    
    private func authFailedResponseJSON() -> Data {
        return try! JSONEncoder().encode(["responseHeader": ["statusMessage": "Authentication failed"]])
    }
    
    private func unknownVendorResponseJSON() -> Data {
        return try! JSONEncoder().encode(["responseHeader": ["statusMessage": "Unknown vendor SOME_VENDOR"]])
    }
    
    private func accessToken() -> String {
        // Experation Date in 2032
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImFwcF81YzA2MWUyZmJlOWNjMDAwMjIwMDMwOWMifQ.eyJzY29wZSI6ImFwcFVzZXIiLCJpYXQiOjE1Nzk2MjI5ODYsInVzZXJJZCI6Ijc3N2FlMDhiLTZhNmItNDJlOS05MDY4LTMxNGRlMDRiYzk4MiIsImV4cCI6MTk3OTYzNzM4Nn0.XvBz-bs3v0A9xyVAlKmBUPZktbuZxjWbcO4OBt5rbeY"
    }
    
    private func fourHoursExpiration() -> TimeInterval {
        return 14400
    }
    
    private func cwtToken() -> String {
        return "eyJhbGciOiJSUzUxMiIsImtpZCI6InRva2VuQ2VydCJ9.eyJzY29wZSI6WyJvcGVuaWQiLCJwcm9maWxlIl0sImNsaWVudF9pZCI6IkN3dFRvR29PYXV0aENsaWVudCIsImp3dE9BdXRoIjoiNjVtMVRxUVMyZHMxVnlwaEpZQk1rWUFqT0FHY1lSbXoiLCJpZG1FbWFpbCI6ImRlQHlvcG1haWwuY29tIiwibGFzdE5hbWUiOiJJRE0iLCJ0b3BJZCI6IjE0OjRhYjczIiwicm9sZXMiOiJ0cmF2ZWxlciIsInRyYXZlbGVyRW1haWwiOiJkZUB5b3BtYWlsLmNvbSIsInRyYXZlbGVyVHlwZUdVSUQiOiIxNDo0MWMzNSIsInN1YklkIjoiMTQ6YzU0NTAiLCJmaXJzdE5hbWUiOiJERSIsIm1pZGRsZU5hbWUiOiJ0ZWFzdCIsImlkIjoiNzc3YWUwOGItNmE2Yi00MmU5LTkwNjgtMzE0ZGUwNGJjOTgyIiwidHJhdmVsZXJHVUlEIjoiMTQ6MjU5Nzc5OGUiLCJ1c2VybmFtZSI6ImRlQHlvcG1haWwuY29tIiwiZXhwIjoxNTcyOTQzNDc3fQ.Lwpy8O_VFXvqf7-yRpR9CDU00sS6GXp9EFnI8vibXcy-MgiCENvqQz39SwaCf5pGM7ASbJyL6axrWtneobOCzpi-ECUx_EvK9nur9DLZ1uEBP65O8ORdrOjcNA3cArGTpvDLccUWFFRYPROutBVpB-WMd7EZ9wuNguDG2pRXa3LvYr7vVdsUiu4pQEDcGfpBE9jcnNm76fNOfne2lBPohhgWi_Nmw37JY_6vmFZPGkiQ5a6dlnwDpd73H93Co-4NFr0TLXkwh9pZJ3voYDnmWDl702IaU2tXmME1vRwKk-9lWkd7W53VeZf04Q9Btml-wrsj4F-HjPVJuxNLk56LCg"
        
    }
}
