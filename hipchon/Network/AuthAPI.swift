//
//  AuthAPI.swift
//  hipchon
//
//  Created by 김범수 on 2022/03/21.
//

import Alamofire
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser
import RxSwift
import SwiftKeychainWrapper

struct APIError: Error {
    let statusCode: Int?
    let description: String?
}

class AuthAPI {
    private init() {}

    public static let shared = AuthAPI()
    static let uri = "https://"
    static let headers: HTTPHeaders = [
        "Authorization": "some auth",
        "Accept": "application/json",
        // TODO: Token
    ]

    // MARK: kakao

    // TODO: 로그인 후 User.me? 에서 userId 받은 후 우리 서버 로그인 API 호출?

    func kakaoSignin() -> Single<Result<String, APIError>> {
        return Single.create { single in
            if AuthApi.hasToken() { // 기존 access token 토큰 존재 여부 체크
                UserApi.shared.accessTokenInfo { _, error in // access token 토큰 요청
                    if error != nil { // access token 토큰 만료 시
                        if UserApi.isKakaoTalkLoginAvailable() { // 앱 로그인: 카톡 어플 O
                            UserApi.shared.loginWithKakaoTalk { _, error in
                                if error != nil { // 로그인 실패
                                    single(.success(.failure(APIError(statusCode: -1, description: error.debugDescription))))
                                } else { // 로그인 성공, userId 발급
                                    UserApi.shared.me(completion: { user, error in
                                        guard let user = user,
                                              let id = user.id
                                        else {
                                            single(.success(.failure(APIError(statusCode: -1, description: error.debugDescription))))
                                            return
                                        }
                                        single(.success(.success(String(id))))
                                    })
                                }
                            }
                        } else { // 웹 로그인: 카톡 어플 X
                            UserApi.shared.loginWithKakaoAccount { _, error in
                                if error != nil { // 로그인 실패
                                    single(.success(.failure(APIError(statusCode: -1, description: error.debugDescription))))
                                } else { // 로그인 성공, userId 발급
                                    UserApi.shared.me(completion: { user, error in
                                        guard let user = user,
                                              let id = user.id
                                        else {
                                            single(.success(.failure(APIError(statusCode: -1, description: error.debugDescription))))
                                            return
                                        }
                                        single(.success(.success(String(id))))
                                    })
                                }
                            }
                        }
                    } else { // 토큰 유효 시, userId 발급
                        UserApi.shared.me(completion: { user, error in
                            guard let user = user,
                                  let id = user.id
                            else {
                                single(.success(.failure(APIError(statusCode: -1, description: error.debugDescription))))
                                return
                            }
                            single(.success(.success(String(id))))
                        })
                    }
                }
            } else { // 토큰 없을 시
                if UserApi.isKakaoTalkLoginAvailable() { // 간편 로그인: 카톡 어플 있을 시
                    UserApi.shared.loginWithKakaoTalk { _, error in
                        if error != nil { // 로그인 실패
                            single(.success(.failure(APIError(statusCode: -1, description: error.debugDescription))))
                        } else { // 로그인 성공, userId 발급
                            UserApi.shared.me(completion: { user, error in
                                guard let user = user,
                                      let id = user.id
                                else {
                                    single(.success(.failure(APIError(statusCode: -1, description: error.debugDescription))))
                                    return
                                }
                                single(.success(.success(String(id))))
                            })
                        }
                    }
                } else { // 카톡 어플 없을 시
                    UserApi.shared.loginWithKakaoAccount { _, error in
                        if error != nil {
                            single(.success(.failure(APIError(statusCode: -1, description: error.debugDescription))))
                        } else { // 로그인 성공, userId 발급
                            UserApi.shared.me(completion: { user, error in
                                guard let user = user,
                                      let id = user.id
                                else {
                                    single(.success(.failure(APIError(statusCode: -1, description: error.debugDescription))))
                                    return
                                }
                                single(.success(.success(String(id))))
                            })
                        }
                    }
                }
            }
            return Disposables.create()
        }
    }

    func signin(authModel: Auth) -> Single<Result<User, APIError>> {
        return Single.create { single in

            guard let loginId = authModel.id,
                  let loginType = authModel.type
            else {
                single(.success(.failure(APIError(statusCode: -1, description: "parameter error"))))
                return Disposables.create()
            }

            guard let url = URL(string: "\(APIParameters.shared.hostUrl)/api/user/\(loginType)/\(loginId)") else {
                single(.success(.failure(APIError(statusCode: -1, description: "url error"))))
                return Disposables.create()
            }
            print("signin")

            APIParameters.shared.session
                .request(url, method: .get, parameters: nil, headers: APIParameters.shared.headers)
                .validate(statusCode: 200 ..< 300)
                .responseJSON(completionHandler: { response in
                    switch response.result {
                    case .success:
                        if let data = response.data {
                            do {
                                let model = try JSONDecoder().decode(User.self, from: data)

                                KeychainWrapper.standard.set("\(model.id ?? -1)", forKey: "userId")
                                KeychainWrapper.standard.set(loginId, forKey: "loginId")
                                KeychainWrapper.standard.set(loginType, forKey: "loginType")
                                APIParameters.shared.refreshUserId()

                                single(.success(.success(model)))
                            } catch {
                                single(.success(.failure(APIError(statusCode: -1, description: "parsing error"))))
                            }
                        }
                    case let .failure(error):
                        guard let statusCode = response.response?.statusCode else {
                            single(.success(.failure(APIError(statusCode: error._code,
                                                              description: error.errorDescription))))
                            return
                        }
                        single(.success(.failure(APIError(statusCode: statusCode, description: error.errorDescription))))
                    }
                })
                .resume()

            return Disposables.create()
        }
    }

    func getUser() -> Single<Result<User, APIError>> {
        return Single.create { single in
            guard let loginId = KeychainWrapper.standard.string(forKey: "loginId"),
                  let loginType = KeychainWrapper.standard.string(forKey: "loginType")
            else {
                single(.success(.failure(APIError(statusCode: -1, description: "parameter error"))))
                return Disposables.create()
            }

            guard let url = URL(string: "\(APIParameters.shared.hostUrl)/api/user/\(loginType)/\(loginId)") else {
                single(.success(.failure(APIError(statusCode: -1, description: "url error"))))
                return Disposables.create()
            }
            print("getUser")

            APIParameters.shared.session
                .request(url, method: .get, parameters: nil, headers: APIParameters.shared.headers)
                .validate(statusCode: 200 ..< 300)
                .responseJSON(completionHandler: { response in
                    switch response.result {
                    case .success:
                        if let data = response.data {
                            do {
                                let model = try JSONDecoder().decode(User.self, from: data)
                                single(.success(.success(model)))
                            } catch {
                                single(.success(.failure(APIError(statusCode: -1, description: "parsing error"))))
                            }
                        }
                    case let .failure(error):
                        guard let statusCode = response.response?.statusCode else {
                            single(.success(.failure(APIError(statusCode: error._code,
                                                              description: error.errorDescription))))
                            return
                        }
                        single(.success(.failure(APIError(statusCode: statusCode, description: error.errorDescription))))
                    }
                })
                .resume()
            return Disposables.create()
        }
    }

    func signup(authModel: Auth) -> Single<Result<Void, APIError>> {
        return Single.create { single in
            print("signup")
            guard let url = URL(string: "\(APIParameters.shared.hostUrl)/api/user") else {
                single(.success(.failure(APIError(statusCode: -1, description: "uri error"))))
                return Disposables.create()
            }

            guard let loginId = authModel.id,
                  let loginType = authModel.type,
                  let isMarketing = authModel.maketingAgree,
                  let name = authModel.name  else {
                single(.success(.failure(APIError(statusCode: -1, description: "parameter error"))))
                return Disposables.create()
            }
            
            let header: HTTPHeaders = [
                "Accept": "application/json",
                "Content-Type": "multipart/form-data",
            ]
            
            let parameters: [String: Any] = [
                "loginId": loginId,
                "loginType": loginType,
                "name": name,
                "isMarketing": isMarketing,
            ]

            APIParameters.shared.session
                .upload(multipartFormData: { multipartFormData in
                    
                    if let profileImage = authModel.profileImage {
                        let resizeImage = profileImage.downSample2(size: profileImage.size, scale: 0.5)
                        let imageData = resizeImage.jpegData(compressionQuality: 0.5)!
                        multipartFormData.append(imageData, withName: "file",
                                                 fileName: "\(Date().timeIntervalSince1970).png",
                                                 mimeType: "image/png")
                    } else {
                        multipartFormData.append("".data(using: .utf8)!, withName: "file",
                                                 fileName: "\(Date().timeIntervalSince1970).png",
                                                 mimeType: "image/png")
                    }

                    if let data = try? JSONSerialization.data(withJSONObject: parameters, options: []) {
                        multipartFormData.append(data, withName: "user", mimeType: "application/json")
                    }
                    
                }, to: url, usingThreshold: UInt64.init(), method: .post, headers: header)
                .response(completionHandler: { response in
                    switch response.result {
                    case .success:
                        single(.success(.success(())))
                    case let .failure(error):
                        guard let statusCode = response.response?.statusCode else {
                            single(.success(.failure(APIError(statusCode: error._code,
                                                              description: error.errorDescription))))
                            return
                        }
                        single(.success(.failure(APIError(statusCode: statusCode, description: error.errorDescription))))
                    }
                })
                .resume()
            
            return Disposables.create()
        }
    }

    func withdraw() -> Single<Result<Void, APIError>> {
        return Single.create { single in
            guard let loginId = KeychainWrapper.standard.string(forKey: "loginId"),
                  let loginType = KeychainWrapper.standard.string(forKey: "loginType")
            else {
                single(.success(.failure(APIError(statusCode: -1, description: "parameter error"))))
                return Disposables.create()
            }

            guard let url = URL(string: "\(APIParameters.shared.hostUrl)/api/user/\(loginType)/\(loginId)") else {
                single(.success(.failure(APIError(statusCode: -1, description: "uri error"))))
                return Disposables.create()
            }

            APIParameters.shared.session
                .request(url, method: .delete, parameters: nil, headers: APIParameters.shared.headers)
                .validate(statusCode: 200 ..< 300)
                .response(completionHandler: { response in
                    switch response.result {
                    case .success:
                        KeychainWrapper.standard.remove(forKey: "userId")
                        KeychainWrapper.standard.remove(forKey: "loginId")
                        KeychainWrapper.standard.remove(forKey: "loginType")
                        APIParameters.shared.refreshUserId()
                        single(.success(.success(())))
                    case let .failure(error):
                        guard let statusCode = response.response?.statusCode else {
                            single(.success(.failure(APIError(statusCode: error._code,
                                                              description: error.errorDescription))))
                            return
                        }
                        single(.success(.failure(APIError(statusCode: statusCode, description: error.errorDescription))))
                    }
                })
                .resume()

            return Disposables.create()
        }
    }

    func editProfile(name: String, image: UIImage?) -> Single<Result<Void, APIError>> {
        return Single.create { single in
            print("putProfileImage")
            guard let url = URL(string: "\(APIParameters.shared.hostUrl)/api/user") else {
                single(.success(.failure(APIError(statusCode: -1, description: "uri error"))))
                return Disposables.create()
            }

            let header: HTTPHeaders = [
                "Accept": "application/json",
                "Content-Type": "multipart/form-data",
            ]
            
            let parameters: [String : Any] = [
                "loginId": KeychainWrapper.standard.string(forKey: "loginId") ?? "",
                "loginType": KeychainWrapper.standard.string(forKey: "loginType") ?? "",
                "name": name,
            ]

            APIParameters.shared.session
                .upload(multipartFormData: { multipartFormData in
                    
                    if let profileImage = image {
                        let resizeImage = profileImage.downSample2(size: profileImage.size, scale: 0.5)
                        let imageData = resizeImage.jpegData(compressionQuality: 0.5)!
                        multipartFormData.append(imageData, withName: "file",
                                                 fileName: "\(Date().timeIntervalSince1970).png",
                                                 mimeType: "image/png")
                    }

                    if let data = try? JSONSerialization.data(withJSONObject: parameters, options: []) {
                        multipartFormData.append(data, withName: "user", mimeType: "application/json")
                    }
                    
                }, to: url, usingThreshold: UInt64.init(), method: .put, headers: header)
                .response(completionHandler: { response in
                    switch response.result {
                    case .success:
                        single(.success(.success(())))
                    case let .failure(error):
                        guard let statusCode = response.response?.statusCode else {
                            single(.success(.failure(APIError(statusCode: error._code,
                                                              description: error.errorDescription))))
                            return
                        }
                        single(.success(.failure(APIError(statusCode: statusCode, description: error.errorDescription))))
                    }
                })
                .resume()
            
            return Disposables.create()
        }
    }
}
