//
//  LocationCell.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class LocationCell: UICollectionViewCell {
    
    var nameLabel : UILabel!
    var dragHandle : UIView!
    let padding : CGFloat = 5
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        nameLabel = UILabel()
        nameLabel.textAlignment = .left
        nameLabel.textColor = UIColor.black
        nameLabel.font = UIFont.systemFont(ofSize: 10.0)
        contentView.addSubview(nameLabel)
        
        let sideLength : CGFloat = 25.0
        let x = contentView.bounds.size.width - sideLength - 5
        let y = (contentView.bounds.size.height - sideLength)/2
        dragHandle = UIView(frame: CGRect(x: x, y: y, width: sideLength, height: sideLength))
        dragHandle.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        contentView.addSubview(dragHandle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
