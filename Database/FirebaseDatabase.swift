//
//  FirebaseDatabase.swift
//  AlarmPill
//
//  Created by JingyuJung on 2019/11/20.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseDatabase {

    static let shared = FirebaseDatabase()

    private let database = Database.database().reference()
    private let decoder = JSONDecoder()

    private init() {}

    func loadObjects<D: FirebaseObject>(path: String, type: D.Type, completion: @escaping (_ object: D)->()) {
        pathToRef(path).observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let snapShotValue = snapshot.value,
                let data = try? JSONSerialization.data(withJSONObject: snapShotValue) else {
                fatalError()
            }

            guard let value = try? self?.decoder.decode(type, from: data) else {
                fatalError()
            }
            completion(value)
        }
    }

    func loadObjects<D: FirebaseObject>(path: String, type: [D].Type, completion: @escaping (_ object: [D])->()) {
        pathToRef(path).observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let snapShotValue = snapshot.value,
                let data = try? JSONSerialization.data(withJSONObject: snapShotValue) else {
                fatalError()
            }

            guard let dictionary = try? self?.decoder.decode(Dictionary<String, D>.self, from: data) else {
                fatalError()
            }

            var values = [D]()
            for (key, value) in dictionary {
                let object = value
                object.key = key
                values.append(object)
            }

            completion(values)
        }
    }

    // Path에 Value를 Set 한다.
    func setObject(path: String, object: FirebaseObject) {
        pathToRef(path).updateChildValues(object.asDict())
    }

    // Path에 Value를 추가한다.
    func addObject(path: String, object: FirebaseObject) {
        pathToRef(path).childByAutoId().updateChildValues(object.asDict())
    }

    func delete(path: String, object: FirebaseObject) {
        let deletePath = "\(path)/\(object.key ?? "")"
        pathToRef(deletePath).removeValue()
    }

    private func pathToRef(_ routesString : String) -> DatabaseReference {
        let routes = routesString.components(separatedBy: "/").filter { !$0.isEmpty }

        var ref = database
        for route in routes {
            ref = ref.child(route)
        }

        return ref
    }
}
