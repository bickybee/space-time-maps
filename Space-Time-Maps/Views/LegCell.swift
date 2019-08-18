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
    var gradientView : UIView!
    let padding : CGFloat = 5
    let cellInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientView(frame: frame)
        setupLabel(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupGradientView(frame: CGRect) {
        let width : CGFloat = 10.0
        let gradientFrame = CGRect(x: frame.width / 4.0 - width / 2.0, y: 0, width: width, height: frame.height)
        gradientView = UIView(frame: gradientFrame)
        contentView.addSubview(gradientView)
    }
    
    func setupLabel(frame: CGRect) {
        timeLabel = UILabel()
        
        timeLabel.textAlignment = .left
        timeLabel.textColor = UIColor.gray
        timeLabel.font = UIFont.systemFont(ofSize: 10.0)
        timeLabel.backgroundColor = .clear
        timeLabel.numberOfLines = 0
        timeLabel.frame = contentView.frame.inset(by: cellInsets)
        
        contentView.addSubview(timeLabel)
    }
    
}
