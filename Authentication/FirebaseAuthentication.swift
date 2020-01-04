//
//  FirebaseAuthentication.swift
//  iOS-Firebase
//
//  Created by JingyuJung on 2019/11/18.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import Foundation
import AuthenticationServices
import FirebaseAuth
import CommonCrypto

enum FirebaseAuthenticationNotification: String {
    case signOutSuccess
    case signOutError
    case signInSuccess
    case signInError
    
    var notificationName: NSNotification.Name {
        return NSNotification.Name(rawValue: self.rawValue)
    }
}

enum FirebaseAuthenticationKey: String {
    case userIntegration = "UserIntegrationKey"
}

class FirebaseAuthentication: NSObject {
    static let shared = FirebaseAuthentication()

    fileprivate var currentNonce: String?
    
    private override init() {}
    
    func currentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    func signUpWithEmail(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            if error != nil {
                self?.postNotificationSignInError()
                return
            }
            self?.postNotificationSignInSuccess()
        }
    }

    func signInWithEmail(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let user = authResult?.user, error == nil else {
                self?.postNotificationSignInError()
                return
            }
            self?.registerUser(user: user)
            self?.postNotificationSignInSuccess()
        }
    }
    
    @available(iOS 13.0, *)
    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func signInWithAnonymous() {
        Auth.auth().signInAnonymously() { [weak self] (authResult, error) in
            guard let user = authResult?.user, error == nil else {
                self?.postNotificationSignInError()
                return
            }
            self?.registerUser(user: user)
            self?.postNotificationSignInSuccess()
        }
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            _integrationKey = nil
            UserDefaultsService.shared.set(key: FirebaseAuthenticationKey.userIntegration.rawValue, "")
            postNotificationSignOutSuccess()
        } catch {
            postNotificationSignOutError()
        }
    }

    func deleteUser() {
        let firebaseAuth = Auth.auth()
        firebaseAuth.currentUser?.delete(completion: nil)
    }

    // Third-party 로그인 통합을 위한 함수. API Path로 사용할 Unique Key 생성
    private func registerUser(user: User) {
        let integrationKey = FirebaseDatabase.shared.addAuthID(path: "private/user-integration-keys")
        FirebaseDatabase.shared.setObject(path: "private/user-integration-keys/\(integrationKey)", object: user.uid)
        FirebaseDatabase.shared.setObject(path: "private/users/\(user.uid)/integration-key", object: integrationKey)
        UserDefaultsService.shared.set(key: FirebaseAuthenticationKey.userIntegration.rawValue, integrationKey)
    }

    // Third-party 로그인 통합을 위한 함수. 현재 계정에 연결된 Integration Key를 반환
    var _integrationKey: String?
    func integrationKey() -> String {
        if let key = _integrationKey {
            return key
        }

        if let key = UserDefaultsService.shared.getString(key: FirebaseAuthenticationKey.userIntegration.rawValue), key.count > 0 {
            _integrationKey = key
            return key
        }

        guard let UID = FirebaseAuthentication.shared.currentUser()?.uid else {
            fatalError()
        }

        FirebaseDatabase.shared.loadObjects(path: "private/users/\(UID)/integration-key", type: String.self) { [weak self] integrationKey in
            self?._integrationKey = integrationKey
        }

        fatalError()
    }
}

@available(iOS 13.0, *)
extension FirebaseAuthentication: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                guard let user = authResult?.user, error == nil else {
                    self?.postNotificationSignInError()
                    return
                }
                self?.registerUser(user: user)
                self?.postNotificationSignInSuccess()
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        postNotificationSignInError()
    }
}

extension FirebaseAuthentication: ASAuthorizationControllerPresentationContextProviding {
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
}

extension FirebaseAuthentication {
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if length == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = hashSHA256(data: inputData)
        let hashString = hashedData!.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func hashSHA256(data:Data) -> Data? {
        var hashData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        
        _ = hashData.withUnsafeMutableBytes {digestBytes in
            data.withUnsafeBytes {messageBytes in
                CC_SHA256(messageBytes, CC_LONG(data.count), digestBytes)
            }
        }
        return hashData
    }
    
    private func postNotificationSignInSuccess() {
        NotificationCenter.default.post(name: FirebaseAuthenticationNotification.signInSuccess.notificationName, object: nil)
    }
    
    private func postNotificationSignInError() {
        NotificationCenter.default.post(name: FirebaseAuthenticationNotification.signInError.notificationName, object: nil)
    }
    
    private func postNotificationSignOutSuccess() {
        NotificationCenter.default.post(name: FirebaseAuthenticationNotification.signOutSuccess.notificationName, object: nil)
    }
    
    private func postNotificationSignOutError() {
        NotificationCenter.default.post(name: FirebaseAuthenticationNotification.signOutError.notificationName, object: nil)
    }
}
