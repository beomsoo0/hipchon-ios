//
//  UserModel.swift
//  hipchon
//
//  Created by 김범수 on 2022/02/14.
//

import Alamofire
import RxSwift

class User: Codable {
    let id: Int?
    let name: String?
    let profileImageURL: String?
    let reviewCount: Int?

    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case name
        case profileImageURL = "image"
        case reviewCount = "postCnt"
    }

    init(id: Int, name: String, profileImageURL: String, reviewCount: Int) {
        self.id = id
        self.name = name
        self.profileImageURL = profileImageURL
        self.reviewCount = reviewCount
    }

    init() {
        id = nil
        name = nil
        profileImageURL = nil
        reviewCount = nil
    }
}
