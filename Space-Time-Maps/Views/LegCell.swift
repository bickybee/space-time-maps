//
//  LegCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 16/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class LegCell: UICollectionViewCell {
    
    var timeLabel : UILabel!
    let padding : CGFloat = 5
    let cellInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLabel() {
        timeLabel = UILabel()
        
        timeLabel.textAlignment = .left
        timeLabel.textColor = UIColor.white
        timeLabel.font = UIFont.systemFont(ofSize: 10.0)
        timeLabel.backgroundColor = .clear
        timeLabel.numberOfLines = 0
        timeLabel.frame = contentView.frame.inset(by: cellInsets)
        
        contentView.addSubview(timeLabel)
    }
    
}
