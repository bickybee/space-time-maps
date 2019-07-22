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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        nameLabel = UILabel()
        nameLabel.textAlignment = .center
        nameLabel.textColor = UIColor.black
        nameLabel.sizeToFit()
        contentView.addSubview(nameLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
