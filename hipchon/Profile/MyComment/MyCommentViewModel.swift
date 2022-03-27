//
//  MyCommentViewModel.swift
//  hipchon
//
//  Created by 김범수 on 2022/03/20.
//

import RxCocoa
import RxSwift

class MyCommentViewModel {
    private let bag = DisposeBag()

    // MARK: subViewModels

    // MARK: viewModel -> view

    let activating: Signal<Bool>
    let commentTableViewHidden: Driver<Bool>
    let myCommentCellVMs: Driver<[MyCommentCellViewModel]>
    let pushReviewDetailVC: Signal<ReviewDetailViewModel>

    // MARK: view -> viewModel

    let viewAppear = PublishRelay<Void>()
    let reload = PublishRelay<Void>()
    let moreFetching = PublishRelay<Void>()
    let selectedCommentIdx = PublishRelay<Int>()

    init() {
        let comments = BehaviorSubject<[CommentModel]>(value: [])

        myCommentCellVMs = comments
            .map { $0.map { MyCommentCellViewModel($0) } }
            .asDriver(onErrorJustReturn: [])

        Observable.merge(
            viewAppear.take(1),
            Singleton.shared.myCommentRefresh
        )
            .flatMap { _ in NetworkManager.shared.getMyComments() }
            .bind(to: comments)
            .disposed(by: bag)

        // refresh
        let activatingState = PublishSubject<Bool>()

        activating = activatingState
            .asSignal(onErrorJustReturn: false)

        reload
            .do(onNext: { activatingState.onNext(true) })
            .flatMap { NetworkManager.shared.getMyComments() }
            .do(onNext: { _ in activatingState.onNext(false) })
            .bind(to: comments)
            .disposed(by: bag)

        // more fetching

        moreFetching
            .flatMap { _ in NetworkManager.shared.getMyComments() }
            .withLatestFrom(comments) { $1 + $0 }
            .bind(to: comments)
            .disposed(by: bag)

        commentTableViewHidden = comments
            .map { $0.count == 0 }
            .asDriver(onErrorJustReturn: false)

        // scene

        pushReviewDetailVC = selectedCommentIdx
            .withLatestFrom(comments) { $1[$0] }
            .compactMap { $0.review }
            .map { ReviewDetailViewModel($0) }
            .asSignal(onErrorSignalWith: .empty())
    }
}
