//
//  Models.swift
//  RealmWithoutNotifying
//
//  Created by Yu Sugawara on 12/5/16.
//  Copyright © 2016 Yu Sugawara. All rights reserved.
//

import Foundation
import RealmSwift

class DemoList: Object {
    
    dynamic var id = defaultID
    let objects = List<DemoObject>()
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    static var defaultID = 0
    
}

class DemoObject: Object {
    
    dynamic var id = 0
    dynamic var date = Date()
    
}
