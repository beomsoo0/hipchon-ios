//
//  SettingViewModel.swift
//  hipchon
//
//  Created by 김범수 on 2022/02/13.
//

import RxCocoa
import RxSwift

class SettingViewModel {
    private let bag = DisposeBag()

    // MARK: subViewModels

    // MARK: viewModel -> view

    let logoutPopToOnBoarding: Signal<Void>
    let withdrawPopToOnBoarding: Signal<Void>

    // MARK: view -> viewModel

    let logoutButtonTapped = PublishRelay<Void>()
    let withdrawButtonTapped = PublishRelay<Void>()
    let partnershipButtonTapped = PublishRelay<Void>()
    let customerServiceButtonTapped = PublishRelay<Void>()

    init() {
        let logoutComplete = PublishSubject<Void>()
        let withdrawComplete = PublishSubject<Void>()

        logoutPopToOnBoarding = logoutComplete
            .asSignal(onErrorJustReturn: ())

        withdrawPopToOnBoarding = withdrawComplete
            .asSignal(onErrorJustReturn: ())

        logoutButtonTapped
            .subscribe(onNext: {
                // TODO: Local Info Delete
                logoutComplete.onNext(())
            })
            .disposed(by: bag)

        withdrawButtonTapped
            .flatMap { AuthManager.shared.withdraw() }
            .subscribe(onNext: { result in
                switch result {
                case .success:
                    withdrawComplete.onNext(())
                case let .failure(error):
                    print(error.description)
                }
            })
            .disposed(by: bag)
    }
}
