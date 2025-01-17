//
//  ReviewComplimentListViewModel.swift
//  hipchon
//
//  Created by 김범수 on 2022/03/05.
//

import RxCocoa
import RxSwift

class ReviewKeywordListViewModel {
    // MARK: viewModel -> view

    let keywordEmpty: Driver<Bool>
    let firstKeywordVM: Driver<KeywordDetailViewModel>
    let secondKeywordVM: Driver<KeywordDetailViewModel>
    let thirdKeywordVM: Driver<KeywordDetailViewModel>

    // MARK: view -> viewModel

    init(_ data: [Keyword]) {
        let keywords = BehaviorSubject<[Keyword]>(value: data)

        firstKeywordVM = keywords
            .filter { $0.count >= 1 }
            .map { $0[0] }
            .map { KeywordDetailViewModel($0) }
            .asDriver(onErrorDriveWith: .empty())

        secondKeywordVM = keywords
            .filter { $0.count >= 2 }
            .map { $0[1] }
            .map { KeywordDetailViewModel($0) }
            .asDriver(onErrorDriveWith: .empty())

        thirdKeywordVM = keywords
            .filter { $0.count >= 3 }
            .map { $0[2] }
            .map { KeywordDetailViewModel($0) }
            .asDriver(onErrorDriveWith: .empty())
        
        keywordEmpty = keywords
            .map { $0.count == 0 }
            .asDriver(onErrorJustReturn: false)
    }
}
