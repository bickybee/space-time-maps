//
//  DataManager.swift
//  Space-Time-Maps
//
//  Created by Vicky on 05/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class DataManager: NSObject {

    var queryService : QueryService
    
    init(_ qs: QueryService) {
        self.queryService = qs
    }
    
}
