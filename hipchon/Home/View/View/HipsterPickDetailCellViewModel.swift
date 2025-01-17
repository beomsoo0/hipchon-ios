//
//  HipsterPickDetailCellViewModel.swift
//  hipchon
//
//  Created by 김범수 on 2022/03/14.
//

import RxCocoa
import RxSwift

class HipsterPickDetailCellViewModel {
    private let bag = DisposeBag()

    // MARK: subViewModels

    let pageCountVM = PageCountViewModel()
    let reviewPlaceVM: Driver<ReviewPlaceViewModel>
    let pushPlaceDetailVC: Signal<PlaceDetailViewModel>
    let share: Signal<String>

    // MARK: viewModel -> view

    let imageURLs: Driver<[URL]>
    let title: Driver<String>
    let content: Driver<String>

    // MARK: view -> viewModel

    let currentIdx = BehaviorRelay<Int>(value: 1)

    init(_ data: HipsterPickModel) {
        let hipsterPick = BehaviorSubject<HipsterPickModel>(value: data)

        imageURLs = hipsterPick
            .compactMap { $0.imageURLs }
            .compactMap { $0.compactMap { URL(string: $0) } }
            .asDriver(onErrorJustReturn: [])

        title = hipsterPick
            .compactMap { $0.title }
            .asDriver(onErrorJustReturn: "")

        content = hipsterPick
            .compactMap { $0.content }
            .asDriver(onErrorJustReturn: "")

        hipsterPick
            .compactMap { $0.imageURLs?.count }
            .bind(to: pageCountVM.entireIdx)
            .disposed(by: bag)

        currentIdx
            .map { $0 + 1 }
            .bind(to: pageCountVM.currentIdx)
            .disposed(by: bag)

        reviewPlaceVM = hipsterPick
            .compactMap { $0.place }
            .map { BehaviorSubject<Place>(value: $0) }
            .map { ReviewPlaceViewModel($0) }
            .asDriver(onErrorDriveWith: .empty())

        pushPlaceDetailVC = reviewPlaceVM
            .flatMap { $0.pushPlaceDetailVC }

        share = reviewPlaceVM
            .flatMap { $0.share }
    }
}
