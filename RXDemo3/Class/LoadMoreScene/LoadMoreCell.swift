//
//  LoadMoreCell.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/16.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit
import UIKit
import RxSwift
import IGListKit
import RxCocoa

class LoadMoreCellModel: CellModel {
    
    var title: Driver<String>
    
    init(title: Driver<String>) {
        self.title = title
        super.init()
    }
    
    override func calculateSize(for containerSize: CGSize) -> CGSize {
        return CGSize(width: containerSize.width, height: 80)
    }
}

class LoadMoreCollectionViewCell: BaseCollectionViewCell {
    
    var titleLabel: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
        }
        
        self.backgroundColor = UIColor.white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func bindCellModel(_ cellModel: CellModel) {
        guard let cellModel = cellModel as?  LoadMoreCellModel else { return }
        disposeBag = DisposeBag()
        
        cellModel.title.drive(titleLabel.rx.text).disposed(by: disposeBag)
    }
    
}
