//
//  RouteCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 04/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class RouteCell: UICollectionViewCell {

    @IBOutlet weak var routeLine: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    var durationLine : UIView!
    var topBorder : UIView!
    var bottomBorder : UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        
        let width = routeLine.frame.width
        let height : CGFloat = 0.0
        let x : CGFloat = 0.0
        let y = routeLine.bounds.size.height / 2.0
        let frame = CGRect(x: x, y: y, width: width, height: height)
        
//        topBorder = UIView(frame: CGRect(x: x, y: y - 2.0, width: width, height: 2.0))
//        topBorder.backgroundColor = .darkGray
//        bottomBorder = UIView(frame: CGRect(x: x, y: y + height, width: width, height: 2.0))
//        bottomBorder.backgroundColor = .darkGray
//        routeLine.addSubview(topBorder)
//        routeLine.addSubview(bottomBorder)
        
        durationLine = UIView(frame: frame)
        durationLine.backgroundColor = .red
        routeLine.addSubview(durationLine)
        self.isUserInteractionEnabled = false
    }

    
    func configureWith(duration: TimeInterval, hourHeight: CGFloat) {
        let height = CGFloat(duration.inHours()) * hourHeight
        configureDurationWithHeight(height)
    }
    
    private func configureDurationWithHeight(_ height: CGFloat) {
        
        let width = routeLine.frame.width
        let x : CGFloat = 0
        let y = (routeLine.bounds.size.height / 2.0) - (height / 2.0)
        let frame = CGRect(x: x, y: y, width: width, height: height)
        
//        topBorder.frame = CGRect(x: x, y: y, width: width, height: 2.0)
//        bottomBorder.frame = CGRect(x: x, y: y + height, width: width, height: 2.0)
        durationLine.frame = frame
        
    }
    
    func configureWith(timing: Timing, duration: TimeInterval, hourHeight: CGFloat, gradient: [UIColor]) {
        let height = CGFloat(duration.inHours()) * hourHeight
        let width = routeLine.frame.width
        let x : CGFloat = 0
        let y = (CGFloat(timing.duration.inHours()) * hourHeight - height) / 2.0
        let frame = CGRect(x: x, y: y, width: width, height: height)
        let colors = ColorUtils.colorWithGradient(frame: frame, colors: gradient)
        
//        topBorder.frame = CGRect(x: x, y: y, width: width, height: 2.0)
//        bottomBorder.frame = CGRect(x: x, y: y + height, width: width, height: 2.0)
        durationLine.frame = frame
        durationLine.backgroundColor = colors ?? gradient[0]
        
        let timeString = Utils.secondsToRelativeTimeString(seconds: duration)
        timeLabel.text = timeString
    }
    
}
