//
//  PickView.swift
//  hipchon
//
//  Created by 김범수 on 2022/02/16.
//

import RxCocoa
import RxSwift
import Then
import UIKit

class PickView: UIView {
    private let bag = DisposeBag()

    private lazy var titleLabel = UILabel().then {
        $0.text = "로컬 힙스터 픽"
        $0.font = .systemFont(ofSize: 20.0, weight: .medium)
    }

    private lazy var picksCollectionView = UICollectionView(frame: .zero,
                                                            collectionViewLayout: UICollectionViewFlowLayout()).then {
        let layout = UICollectionViewFlowLayout()
        let itemSpacing = 8.0
        let width = 230.0
        let height = 284.0

        layout.itemSize = CGSize(width: width, height: height)
        layout.sectionInset = UIEdgeInsets(top: 0.0, left: 30.0, bottom: 0.0, right: 0.0)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing

        $0.collectionViewLayout = layout
        $0.register(PickCell.self, forCellWithReuseIdentifier: PickCell.identyfier)
        $0.showsHorizontalScrollIndicator = false
        $0.bounces = false
        $0.isPagingEnabled = true
        $0.backgroundColor = .white
    }
    
    private lazy var selectView = UIView().then {
        $0.backgroundColor = .black
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        attribute()
        layout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(_ viewModel: PickViewModel) {
        viewModel.picks
            .drive(picksCollectionView.rx.items) { col, idx, data in
                guard let cell = col.dequeueReusableCell(withReuseIdentifier: PickCell.identyfier, for: IndexPath(row: idx, section: 0)) as? PickCell else { return UICollectionViewCell() }
                let pickCellViewModel = PickCellViewModel(data)
                cell.bind(pickCellViewModel)
                return cell
            }
            .disposed(by: bag)
    }

    private func attribute() {
        backgroundColor = .systemGray6
    }

    private func layout() {
        [
            titleLabel,
            picksCollectionView,
            selectView
        ].forEach { addSubview($0) }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(30.0)
            $0.top.equalToSuperview().inset(20.0)
        }

        picksCollectionView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(10.0)
            $0.height.equalTo(284.0)
        }
        
        selectView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(30.0)
            $0.top.equalTo(picksCollectionView.snp.bottom).offset(33.0)
            $0.height.equalTo(2.0)
        }
    }
}
