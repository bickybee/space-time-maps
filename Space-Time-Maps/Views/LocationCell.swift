//
//  LocationCell.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class LocationCell: DraggableCell {
    
    var nameLabel : UILabel!
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
        nameLabel = UILabel()
        
        nameLabel.textAlignment = .left
        nameLabel.textColor = UIColor.black
        nameLabel.font = UIFont.systemFont(ofSize: 10.0)
        nameLabel.backgroundColor = .white
        nameLabel.numberOfLines = 0
        nameLabel.frame = contentView.frame.inset(by: cellInsets)
        
        contentView.addSubview(nameLabel)
    }
    
}
