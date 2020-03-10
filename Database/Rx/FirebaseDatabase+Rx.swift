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
    func loadFirebaseObject<D: FirebaseObject>(path: String, type: D.Type) -> Single<D?> {
        let single = Single<D?>.create { [weak base] single in
            base?.loadFirebaseObject(path: path, type: type) { object in
                guard let object = object else {
                    return single(.error(NSError()))
                }
                return single(.success(object))
            }
            return Disposables.create {}
        }
        return single
    }

    func loadObject<D: Decodable>(path: String, type: D.Type) -> Single<D?> {
        let single = Single<D?>.create { [weak base] single in
            base?.loadObject(path: path, type: type) { object in
                return single(.success(object))
            }
            return Disposables.create {}
        }
        return single
    }

    func loadFirebaseObjects<D: FirebaseObject>(path: String, query: FirebaseDatabaseQuery =  FirebaseDatabaseQuery(), type: [D].Type) -> Single<[D]> {
        let single = Single<[D]>.create { [weak base] single in
            base?.loadFirebaseObjects(path: path, query: query, type: type) { objects in
                return single(.success(objects))
            }
            return Disposables.create {}
        }
        return single
    }

    func loadObjects<D: Decodable>(path: String, query: FirebaseDatabaseQuery? = nil, type: [D].Type) -> Single<[D]> {
        let single = Single<[D]>.create { [weak base] single in
            base?.loadObjects(path: path, query: query, type: type) { objects in
                guard let objects = objects else {
                    return single(.error(NSError()))
                }
                return single(.success(objects))
            }
            return Disposables.create {}
        }
        return single
    }

    func setFirebaseObject(path: String, object: FirebaseObject) -> Single<Void> {
        base.setFirebaseObject(path: path, object: object)
        return .just(Void())
    }
    
    func setObject<D: Decodable>(path: String, object: D) -> Single<Void> {
        base.setObject(path: path, object: object)
        return .just(Void())
    }
    
    func addFirebaseObject(path: String, object: FirebaseObject) -> Single<String> {
        let childID = base.addFirebaseObject(path: path, object: object)
        return .just(childID)
    }
    
    func addObject<D: Decodable>(path: String, object: D) -> Single<Void> {
        base.addObject(path: path, object: object)
        return .just(Void())
    }
    
    func addAuthID(path: String) -> Single<String> {
        return .just(base.addAuthID(path: path))
    }
    
    func delete(path: String, object: FirebaseObject) -> Single<Void> {
        base.delete(path: path, object: object)
        return .just(Void())
    }

    func delete(path: String) -> Single<Void> {
        base.delete(path: path)
        return .just(Void())
    }
}
