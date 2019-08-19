//
//  CollectionViewCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 14/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class DraggableCell: UICollectionViewCell {
    
    var dragHandle : UIView!
    var dragOffset : CGPoint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupHandle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupHandle() {
        let sideLength : CGFloat = 25.0
        let x = contentView.bounds.size.width - sideLength - 5
        let y = (contentView.bounds.size.height - sideLength)/2
        dragHandle = UIView(frame: CGRect(x: x, y: y, width: sideLength, height: sideLength))
        dragHandle.backgroundColor = .white
        dragHandle.layer.zPosition = 100
        dragHandle.layer.cornerRadius = 5;
        dragHandle.layer.masksToBounds = true;
        contentView.addSubview(dragHandle)
        
        dragOffset = CGPoint(x: dragHandle.center.x - contentView.center.x, y: dragHandle.center.y - contentView.center.y)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let newHeight = self.frame.size.height
        dragHandle.center = CGPoint(x: dragHandle.frame.midX, y: newHeight/2)
    }
    
}
