//
//  FirebaseDatabase+Rx.swift
//  iOS-Firebase
//
//  Created by JingyuJung on 2019/11/30.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import RxSwift
import RxCocoa

extension FirebaseDatabase: ReactiveCompatible {}

extension Reactive where Base: FirebaseDatabase {
    func loadObjects<D: FirebaseObject>(path: String, type: D.Type) -> Single<D?> {
        let single = Single<D?>.create { [weak base] single in
            base?.loadObjects(path: path, type: type) { object in
                single(.success(object))
            }
            return Disposables.create {}
        }
        return single
    }

    func loadObjects<D: Decodable>(path: String, type: D.Type) -> Single<D?> {
        let single = Single<D?>.create { [weak base] single in
            base?.loadObjects(path: path, type: type) { object in
                single(.success(object))
            }
            return Disposables.create {}
        }
        return single
    }

    func loadObjects<D: Decodable>(path: String, query: FirebaseDatabaseQuery? = nil, type: [D].Type) -> Single<[D]> {
        return Observable.create { [unowned base] observer -> Disposable in
            base.loadObjects(path: path, query: query, type: type) { object in
                observer.onNext(object)
            }
            return Disposables.create()
        }
        .asSingle()
    }

    func setObject(path: String, object: FirebaseObject) -> Single<Void> {
        base.setObject(path: path, object: object)
        return .just(Void())
    }
    
    func setObject<D: Decodable>(path: String, object: D) -> Single<Void> {
        base.setObject(path: path, object: object)
        return .just(Void())
    }
    
    func addObject(path: String, object: FirebaseObject) -> Single<Void> {
        base.setObject(path: path, object: object)
        return .just(Void())
    }
    
    func addObject<D: Decodable>(path: String, object: D) -> Single<Void> {
        base.setObject(path: path, object: object)
        return .just(Void())
    }
    
    func addAuthID(path: String) -> Single<String> {
        return .just(base.addAuthID(path: path))
    }
    
    func delete(path: String, object: FirebaseObject) -> Single<Void> {
        base.delete(path: path, object: object)
        return .just(Void())
    }
}
