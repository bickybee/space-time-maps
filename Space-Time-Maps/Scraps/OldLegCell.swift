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
    var lineView : UIView!
    let padding : CGFloat = 5
    let gradientWidth : CGFloat = 10.0
    let cellInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false
        
        setupLine(frame: frame)
        setupGradientView(frame: frame)
        setupLabel(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    func setupLine(frame: CGRect) {
        lineView = UIView(frame: contentView.frame)
        contentView.addSubview(lineView)
    }
    
    private func setupGradientView(frame: CGRect) {
        gradientView = UIView(frame: contentView.frame)
        contentView.addSubview(gradientView)
    }
    
    private func setupLabel(frame: CGRect) {
        timeLabel = UILabel()
        
        timeLabel.textAlignment = .left
        timeLabel.textColor = UIColor.gray
        timeLabel.font = UIFont.systemFont(ofSize: 10.0)
        timeLabel.backgroundColor = .clear
        timeLabel.numberOfLines = 0
        timeLabel.frame = contentView.frame.inset(by: cellInsets).offsetBy(dx: contentView.frame.size.width / 2.0 + padding, dy: -5.0)
        timeLabel.frame.size.width /= 2.0
        timeLabel.frame.size.width -= (gradientWidth / 2.0) + padding
        
        contentView.addSubview(timeLabel)
    }
    
    public func setupWith(duration: TimeInterval, hourHeight: CGFloat, startFraction: Double, endFraction: Double) {
        
        let gradient = ColorUtils.gradientFor(startFraction: startFraction, endFraction: endFraction)
        let gradientLayer = CAGradientLayer()
        
        let gHeight = CGFloat(duration.inHours()) * hourHeight
        let gY = (self.frame.size.height / 2.0) - (gHeight / 2.0) // height / 2 work but center.y doesnt??? idk!!!
        let gX = gradientView.center.x - (gradientWidth / 2.0)
        
        gradientLayer.frame = CGRect(x: gX, y: gY, width: gradientWidth, height: gHeight)
        gradientLayer.colors = [gradient.0.cgColor, gradient.1.cgColor]
        gradientLayer.borderColor = UIColor.lightGray.cgColor
        gradientLayer.borderWidth = 0.5
        
        self.gradientView.layer.sublayers = nil
        self.gradientView.layer.addSublayer(gradientLayer)
        
        lineView.frame = CGRect(x: gX, y: 0, width: gradientWidth, height: contentView.frame.size.height)
        lineView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        let timeString = Utils.secondsToRelativeTimeString(seconds: duration)
        self.timeLabel.text = timeString
        self.layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let newHeight = contentView.frame.size.height
        lineView.frame.size.height = newHeight
        gradientView.frame.size.height = newHeight
        timeLabel.frame.size.height = newHeight
    }
    
}
