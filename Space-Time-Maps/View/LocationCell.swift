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
    var dragOffset : CGPoint!
    let padding : CGFloat = 5
    let cellInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLabel()
        setupHandle()
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
    
    func setupHandle() {
        let sideLength : CGFloat = 25.0
        let x = contentView.bounds.size.width - sideLength - 5
        let y = (contentView.bounds.size.height - sideLength)/2
        dragHandle = UIView(frame: CGRect(x: x, y: y, width: sideLength, height: sideLength))
        dragHandle.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        dragHandle.layer.borderColor = UIColor.black.cgColor
        dragHandle.layer.borderWidth = 1
        contentView.addSubview(dragHandle)
        
        dragOffset = CGPoint(x: dragHandle.center.x - contentView.center.x, y: dragHandle.center.y - contentView.center.y)
    }
    
}
