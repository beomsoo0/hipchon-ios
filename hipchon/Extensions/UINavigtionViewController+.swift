//
//  UINavigtionViewController+.swift
//  hipchon
//
//  Created by 김범수 on 2022/03/23.
//

import UIKit

extension UINavigationController {
    func popViewController(animated: Bool, completion: @escaping (() -> Void)) -> UIViewController? {
        CATransaction.setCompletionBlock(completion)
        CATransaction.begin()
        let poppedViewController = popViewController(animated: animated)
        CATransaction.commit()
        return poppedViewController
    }

    func pushViewController(_ viewController: UIViewController, animated: Bool, completion: @escaping (() -> Void)) {
        CATransaction.setCompletionBlock(completion)
        CATransaction.begin()
        pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }

    func popToRootViewController(animated: Bool, completion: @escaping (() -> Void)) {
        CATransaction.setCompletionBlock(completion)
        CATransaction.begin()
        popToRootViewController(animated: animated)
        CATransaction.commit()
    }
}
