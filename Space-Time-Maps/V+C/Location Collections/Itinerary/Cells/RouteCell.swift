//
//  RouteCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 04/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
import ChameleonFramework

class RouteCell: UICollectionViewCell {

    @IBOutlet weak var routeLine: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    var durationLine : UIView!
    
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
        
        durationLine.frame = frame
        
    }
    
    func configureWith(timing: Timing, duration: TimeInterval, hourHeight: CGFloat, gradient: [UIColor]) {
        let height = CGFloat(duration.inHours()) * hourHeight
        let width = routeLine.frame.width
        let x : CGFloat = 0
        let y = (CGFloat(timing.duration.inHours()) * hourHeight - height) / 2.0
        let frame = CGRect(x: x, y: y, width: width, height: height)
        let colors = GradientColor(.topToBottom, frame: frame, colors: gradient)
        
        durationLine.frame = frame
        durationLine.backgroundColor = colors
        
        let timeString = Utils.secondsToRelativeTimeString(seconds: duration)
        timeLabel.text = timeString
    }
    
}
