//
//  AuthModel.swift
//  hipchon
//
//  Created by 김범수 on 2022/02/23.
//

import Foundation

enum RegisterPasswordCheckType {
    case right, length, combination, special
}

class AuthModel: Codable {
    let email: String?
    let password: String?

    enum Codingkeys: String, CodingKey {
        case email, password
    }

    public static func emailValidCheck(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }

    public static func passwordValidCheck(password: String) -> Bool {
        return password.count >= 8 && password.count <= 20
    }

    public static func registerPasswordValidCheck(password: String) -> RegisterPasswordCheckType {
        let lengthreg = ".{8,20}"
        let lengthtesting = NSPredicate(format: "SELF MATCHES %@", lengthreg)
        if lengthtesting.evaluate(with: password) == false {
            return RegisterPasswordCheckType.length
        }
        let combinationreg = "^(?=.*[A-Za-z])(?=.*[0-9]).{8,20}"
        let combinationtesting = NSPredicate(format: "SELF MATCHES %@", combinationreg)
        if combinationtesting.evaluate(with: password) == false {
            return RegisterPasswordCheckType.combination
        }
        let specialreg = "^(?=.*[!@#$%^&*()_+=-]).{8,20}"
        let specialtesting = NSPredicate(format: "SELF MATCHES %@", specialreg)
        if specialtesting.evaluate(with: password) == false {
            return RegisterPasswordCheckType.special
        }
        return RegisterPasswordCheckType.right
    }

    init(email: String?, password: String?) {
        self.email = email
        self.password = password
    }
}