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
    let cellInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 35.0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.cornerRadius = 5;
        self.layer.masksToBounds = true;
        
        setupLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLabel() {
        let container = UIView()
        container.frame = contentView.frame.inset(by: cellInsets)
        container.backgroundColor = .white
        container.layer.cornerRadius = 5;
        container.layer.masksToBounds = true;
        container.layer.zPosition = 0
        
        nameLabel = UILabel()
        nameLabel.textAlignment = .left
        nameLabel.textColor = UIColor.darkGray
        nameLabel.font = UIFont.systemFont(ofSize: 10.0)
        nameLabel.numberOfLines = 0
        nameLabel.frame = container.frame
        nameLabel.frame.size.height = container.frame.size.height - 10.0
        nameLabel.frame.size.width = container.frame.size.width - 10.0
        
        container.addSubview(nameLabel)
        contentView.addSubview(container)
    }
    
}
