//
//  GroupCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 30/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class GroupCell: DestinationCell {
    
    var nextBtn = UIButton()
    var previousBtn = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupButtons() {

        nextBtn.frame = CGRect(x: self.frame.width - 25, y: 0 , width: 25, height: 25)
        previousBtn.frame = CGRect(x: 0, y: 0 , width: 25, height: 25)
        
        nextBtn.backgroundColor = .blue
        previousBtn.backgroundColor = .blue
        
        self.addSubview(nextBtn)
        self.addSubview(previousBtn)
    }
    

    
}
