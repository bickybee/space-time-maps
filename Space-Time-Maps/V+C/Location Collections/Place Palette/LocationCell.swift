//
//  LocationCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 22/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class LocationCell: UICollectionViewCell, Draggable {
    
    var dragHandle : UIView = UIView()
    var container : UIView!
    var nameLabel : UILabel!
    let padding : CGFloat = 5
    let cellInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.cornerRadius = 5;
        self.layer.masksToBounds = true;
        
        setupLabel()
        setupHandle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabel() {
        container = UIView()
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
    
    private func setupHandle() {
        dragHandle.frame = contentView.frame
        dragHandle.backgroundColor = .clear
        dragHandle.layer.zPosition = 1000
        self.addSubview(dragHandle)
    }
    
    public func setupWith(name: String, fraction: Double, constrained: Bool) {
        let color = ColorUtils.colorFor(fraction: fraction)
        self.backgroundColor = color
        self.nameLabel.text = name
        if constrained {
            self.layer.borderColor = UIColor.black.cgColor
            self.layer.borderWidth = 1
        } else {
            self.layer.borderWidth = 0
        }
        self.layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let newHeight = self.frame.size.height - 10.0
        container.frame.size.height = newHeight
        nameLabel.frame.size.height = newHeight - 8.0
    }
    
}
