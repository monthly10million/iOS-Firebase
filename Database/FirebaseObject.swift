//
//  FirebaseObject.swift
//  iOS-Firebase
//
//  Created by JingyuJung on 2019/11/20.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseObject: Decodable {
    var key: String? = nil
}

extension FirebaseObject {
    func asDict() -> [String: Any] {
        var dict = [String: Any]()
        let otherSelf = Mirror(reflecting: self)
        for child in otherSelf.children {
            if let key = child.label {
                dict[key] = child.value
            }
        }
        return dict
    }
}
