//
// Created by fan yang on 2017/9/20.
// Copyright (c) 2017 ___FULLUSERNAME___. All rights reserved.
//

import RxSwift
import Kingfisher
//
//
struct UnknowError: Error {


}
//
extension KingfisherManager : ReactiveCompatible {}
public extension Reactive where Base: KingfisherManager {

    /// Designated request-making method.
    public func request(_ url: URL, options: KingfisherOptionsInfo?) -> Single<Image> {
        return base.rxRequest(url, options: options)
    }
}

internal extension KingfisherManager {

    internal func rxRequest(_ url: URL, options: KingfisherOptionsInfo?) -> Single<Image> {
        return Single.create { [weak self] single in

            let cancellableToken =  self?.retrieveImage(with: url, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, url) in
                if let image = image {
                    single(.success(image))
                }
                else if let error = error {
                    single(.error(error))
                }
                else {
                    single(.error(UnknowError()))
                }
            })

            return Disposables.create {
                cancellableToken?.cancel()
            }
        }
    }

}

