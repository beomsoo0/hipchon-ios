//
//  MenuListViewModel.swift
//  hipchon
//
//  Created by 김범수 on 2022/03/16.
//

import RxCocoa
import RxSwift

class MenuListViewModel {
    let menuCellVMs: Driver<[MenuCellViewModel]>

    init(_ data: [Menu]) {
        let menus = BehaviorSubject<[Menu]>(value: data)

        menuCellVMs = menus
            .map { $0.map { MenuCellViewModel($0) } }
            .asDriver(onErrorJustReturn: [])
    }
}
