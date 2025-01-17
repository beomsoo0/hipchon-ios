//
//  MenuCellViewModel.swift
//  hipchon
//
//  Created by 김범수 on 2022/03/16.
//

import RxCocoa
import RxSwift

class MenuCellViewModel {
    let imageURL: Driver<URL>
    let name: Driver<String>
    let price: Driver<Int>

    init(_ data: Menu) {
        let menu = BehaviorSubject<Menu>(value: data)

        imageURL = menu
            .compactMap { $0.imageURL }
            .compactMap { URL(string: $0) }
            .asDriver(onErrorDriveWith: .empty())

        name = menu
            .compactMap { $0.name }
            .asDriver(onErrorJustReturn: "")

        price = menu
            .compactMap { $0.price }
            .asDriver(onErrorJustReturn: 0)
    }
}
