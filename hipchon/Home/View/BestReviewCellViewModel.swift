//
//  BestReviewCellViewModel.swift
//  hipchon
//
//  Created by 김범수 on 2022/03/02.
//

import RxCocoa
import RxSwift

class BestReviewCellViewModel {
    // MARK: viewModel -> view

    let title: Driver<String>
    let hashtagImageURL: Driver<URL>

    // MARK: view -> viewModel

    init(_ data: BestReview) {
        let bestReview = BehaviorSubject<BestReview>(value: data)

        title = bestReview
            .compactMap { $0.title }
            .asDriver(onErrorJustReturn: "")

        hashtagImageURL = bestReview
            .compactMap { $0.hashtag?.imageURL }
            .compactMap { URL(string: $0) }
            .asDriver(onErrorDriveWith: .empty())
    }
}
