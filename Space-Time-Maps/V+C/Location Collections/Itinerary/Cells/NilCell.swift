//
//  NilCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 05/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class NilCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.alpha = 1.0
        self.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
