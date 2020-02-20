//
//  ClientMediator.swift
//  CWTTests
//
//  Created by Mendy Edri on 07/11/2019.
//

import Foundation
import lit_networking

/** Holds the data ClientMediator needs to be injected with
 ChatClient - Chat SDK or framework, call sdk-start, sdk-login & sdk-logout.
 ChatHTTPClient - Remote API caller, calls appId API call (STS-Metadata) and vendor user token (STS) API */

public struct ClientMediatorClients {
    var chatClient: ChatClient
    var httpClient: HTTPClient
    var tokenAdapter: AccessTokenAdapter
    var jwtClient: Jwtable
    var storage: Storage
    var strategy: BasicProcessStrategy
    var appIdLoader: RemoteAppIdLoader
    var vendorTokenLoader: RemoteClientTokenLoader
    var identityStoreController: IdentityStoreController
}

extension ClientMediator: Commands {}

/** Holds application specific business logic, interact with ChatClient and run the right client request via ChatHTTPClient, according to it state. */

final public class ClientMediator {
    public typealias Result = Swift.Result<String, ClientMediator.Error>
    public typealias APIResult = Swift.Result<String, Error>
    
    /** Prepare function Result-type error */
    public enum Error: Swift.Error {
        case initFailed
        case loginFailed
        case invalidToken
        case sdkNotInitialized
        case logoutFailed
        case failedFetchAppId
        case failedFetchToken
        case failedRegisterIdentity
    }
    
    public enum ClientState: Equatable {
        case notReady
        case ready
        case failed(Error)
    }
    
    public enum RefreshState {
        case start, end
    }
    
    private var clientState: ClientState = .notReady {
        didSet {
            prepareCompletion(clientState)
        }
    }
    
    private var clients: ClientMediatorClients
        
    //private var loaders: Loaders
    
    private var mediatorRetry = MediatorsRetry()
    
    private var prepareCompletion: (ClientState) -> Void = { _ in }
    
    private var vendorTokenCompletion: ((String) -> Void)? = nil
    
    private weak var commands: Commands?
        
    public init(clients: ClientMediatorClients) {
        self.clients = clients
        commands = self
    }
    
    private func updateObeservers(_ token: String) {
        vendorTokenCompletion?(token)
    }
    
    public func onVendorTokenUpdated(_ completion: @escaping (String) -> Void) {
        vendorTokenCompletion = completion
    }
    
    deinit {
        debugPrint("ClientMediator got deallocated")
    }
}

extension ClientMediator {
    
    /** Instantiate Chat SDK and Login */
    
    public func prepare(_ completion: @escaping (ClientState) -> Void) {
        // To support switching between enviroments
        //loaders = Loaders(client: self.clients.httpClient, storage: self.clients.storage)
        
        prepareCompletion = completion
        
        startSDKPreparation(strategy)
    }
    
    public func renewUserToken(completion: @escaping (Result) -> Void) {
        commands?.getRemoteToken(tokenAdapter: clients.tokenAdapter, loader: clients.vendorTokenLoader) { [weak self] result in
            guard let self = self else { return }
            
            self.save(result: result, for: self.userTokenKey)
            return completion(result)
        }
    }
    
    public func logout(_ completion: @escaping (Result) -> Void) {
        chatClient.logout { result in
            result.success { [weak self] in
                self?.cleanChatStorage()
            }
            completion(result)
        }
    }
    
    public func isReady() -> Bool {
        return clientState == .ready
    }
    
    private func startSDKPreparation(_ strategy: BasicProcessStrategy) {
        let strategy = strategy.nextStepExecution()
        debugPrint(strategy)
        
        switch strategy {
        case .remoteFetchAppId:
            appIdCommand()
            
        case .remoteFetchUserToken:
            userTokenCommand()
            
        case .SDKInit:
            startCommand()
            
        case .SDKLogin:
            loginCommand()
            
        case .SDKReadyToUse:
            readyCommand()
        }
    }
    
    private func save(result: Swift.Result<String, ClientMediator.Error>, for key: String) {
        guard case let .success(value) = result else { return }
        storage.save(value: value, for: key)
    }
    
    private func delete(for key: String) {
        storage.delete(key: key)
    }
    
    //MARK: - Helpers
    
    /* Uses Genric function to bypass swift compilation error that it won't compile when the function getting Result<SomeType, Swift.Error> and we send some Swift.Error specific implementation (such as Class.Error),
     In Functions, the same behaviour of passing a spesific implementation of an Error to a generic Swift.Error parameter will work. :\--
     */
    
    private func handle(_ result: Swift.Result<String, Error>) {
        
        switch result {
        case .success:
            self.startSDKPreparation(strategy)
            
        case let .failure(error):
            self.clientState = .failed(error)
        }
    }
    
    private func cleanChatStorage() {
        deleteSavedAppId()
        deleteSavedUserToken()
        deleteSavedIdentityStore()
    }
    
    private func deleteSavedAppId() {
        storage.delete(key: chatClient.appIdKey)
    }
    
    private func deleteSavedUserToken() {
        storage.delete(key: chatClient.userTokenKey)
    }
    
    private func deleteSavedIdentityStore() {
        clients.identityStoreController.clearUserId()
    }
}

private extension ClientMediator {
    // MARK: - Requests Commands
    private func appIdCommand() {
        commands?.getRemoteAppId(loader: clients.appIdLoader, completion: { [weak self] result in
            guard let self = self else { return }
            self.save(result: result, for: self.appIdKey)
            self.handle(result)
        })
    }
    
    private func userTokenCommand(_ completion: ((Result) -> Void)? = nil) {
        commands?.getRemoteToken(tokenAdapter: clients.tokenAdapter, loader: clients.vendorTokenLoader) { [weak self] result in
            guard let self = self else { return }
          
            self.save(result: result, for: self.userTokenKey)
            self.handle(result)
            result.success { token in 
                self.updateObeservers(token)
            }
        }
    }
    
    private func startCommand() {
        self.commands?.startSDK(for: (self.chatClient, self.appId)) { [weak self] result in
            guard let self = self else { return }
            if result.succeeded {
                return self.handle(result)
            }
            result.failure {
                self.delete(for: self.chatClient.appIdKey)
            }
            if self.mediatorRetry.sdkStartRetry?.retry() == false {
                self.handle(result)
            }
        }
        
        self.mediatorRetry.sdkStartRetry?.setAction {
            self.startSDKPreparation(self.strategy)
        }
    }
    
    private func loginCommand() {
        commands?.loginSDK(for: (chatClient, userToken, userId)) { [weak self] result in
            guard let self = self else { return }
            self.registerIdentityStoreCommandWithoutCompletion()
            if result.succeeded {
                return self.handle(result)
            }
            if self.mediatorRetry.sdkLoginRetry?.retry() == false {
                self.handle(result)
            }
        }
        
        self.mediatorRetry.sdkLoginRetry?.setAction {
            self.startSDKPreparation(self.strategy)
        }
    }
    
    private func registerIdentityStoreCommandWithoutCompletion() {
        clients.identityStoreController.registerIfNeeded(tokenAdapter: clients.tokenAdapter) { _ in }
    }
    
    private func readyCommand() {
        clientState = .ready
    }
}

extension ClientMediator {
    /** Mapping between clients property to have easy API */
    
    private var chatClient: ChatClient {
        return clients.chatClient
    }
    
    private var httpClient: HTTPClient {
        return clients.httpClient
    }
    
    private var storage: Storage {
        return clients.storage
    }
    
    private var strategy: BasicProcessStrategy {
        return self.clients.strategy
    }
    
    private var appIdKey: String {
        return clients.chatClient.appIdKey
    }
    
    private var userTokenKey: String {
        return clients.chatClient.userTokenKey
    }
    
    private var appId: String? {
        return clients.storage.value(for: clients.chatClient.appIdKey) as? String
    }
    
    var userToken: String? {
        return clients.storage.value(for: clients.chatClient.userTokenKey) as? String
    }
    
    private var userId: String? {
        if let token = self.clients.storage.value(for: userTokenKey) as? String {
            self.clients.jwtClient.jwtString = token
            return self.clients.jwtClient.value(for: Jwt.CommonKeys.userId.rawValue)
        }
        return nil
    }
}

struct MediatorsRetry {
    static var sdkRetryAttempts: Int {
        return 2
    }
     
    static var httpRetryAttempts: Int {
        return 3
    }
    
    lazy var sdkStartRetry = RetryExecutor(attempts: MediatorsRetry.sdkRetryAttempts)
    lazy var sdkLoginRetry = RetryExecutor(attempts: MediatorsRetry.sdkRetryAttempts)
}
