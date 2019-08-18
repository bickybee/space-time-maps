//
//  TimelineView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 08/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class TimelineView: UIView {
    
    var startTime : TimeInterval = TimeInterval.from(minutes: 15.0)
    var hourHeight : CGFloat = 50
    
    var startOffset : CGFloat {
        let timeInHours = startTime.inHours()
        return CGFloat(1 - timeInHours.truncatingRemainder(dividingBy: 1)) * hourHeight
    }
    
    var numHourTicks : Int {
        let heightMinusOffset = self.frame.height - startOffset
        // How many full hours fit into the remaining time?
        let fullHours = floor(heightMinusOffset / hourHeight)
        return Int(fullHours + 1)
    }
    
    private let lineWidth : CGFloat = 2
    private let stringAttributes = [
        NSAttributedString.Key.paragraphStyle: NSParagraphStyle(),
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 8.0),
        NSAttributedString.Key.foregroundColor: UIColor.lightGray
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initCommon()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initCommon()
    }
    
    func initCommon() {
        self.backgroundColor = UIColor.white
    }
    
    func drawTicks(spacing: CGFloat, tickWidth: CGFloat, timelineWidth: CGFloat) {
        
        let tickPath = UIBezierPath()
        tickPath.lineWidth = lineWidth
        
        for tickNum in 0...(numHourTicks) {
            let y = CGFloat(tickNum) * (spacing) + startOffset + lineWidth
            let startTickAt = CGPoint(x: timelineWidth / 2.0, y: y)
            let endTickAt = CGPoint(x: timelineWidth, y: y)
            tickPath.move(to: startTickAt)
            tickPath.addLine(to: endTickAt)
        }
        
        tickPath.close()
        UIColor.lightGray.set()
        tickPath.stroke()
        
    }
    
    func drawNumbers(spacing: CGFloat) {
        let firstHour = Int(ceil(startTime.inHours()))
        for num in 0...numHourTicks {
            let str = NSAttributedString(string: (firstHour + num).description + ":00", attributes: stringAttributes)
            let x : CGFloat = 0
            let y = CGFloat(num) * spacing + startOffset + lineWidth / 2
            let point = CGPoint(x: x, y: y - 4.0)
            str.draw(at: point)
        }
    }

    override func draw(_ rect: CGRect) {
        print(rect.size.width)
        drawTicks(spacing: hourHeight, tickWidth: rect.width, timelineWidth: rect.width )
        drawNumbers(spacing: hourHeight)
    }

}
