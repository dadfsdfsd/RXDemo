//
// Created by fan yang on 2017/9/20.
// Copyright (c) 2017 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import Kingfisher

class DataProvider {
    
    var disposeBag = DisposeBag()
    
    func cancelAll() {
        disposeBag = DisposeBag()
    }
}


class HttpDataProvider: DataProvider {
    
    
    
}


class ImageDataProvider: DataProvider {
    
    var shared = ImageDataProvider()
    
    var kingfisherManager = KingfisherManager.shared
    
    public func request(_ url: URL, options: KingfisherOptionsInfo?) -> Single<Image> {
        return kingfisherManager.rx.request(url, options: options)
    }
    
    
}


class ZHDataProvider: HttpDataProvider {

    var networkProvider = MoyaProvider<ZHApi>()

    func updateData(of target: ZHApi) -> Single<Response> {
        let request = networkProvider.rx.request(target)
        return request

    }
    
}
