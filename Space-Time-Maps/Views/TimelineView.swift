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
    var sidebarWidth : CGFloat = 50
    var currentTime : TimeInterval = 0
    
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
    
    private let tickOverflow : CGFloat = 10
    private let lineWidth : CGFloat = 1
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
            let x = sidebarWidth - tickOverflow
            let y = CGFloat(tickNum) * (spacing) + startOffset
            let startTickAt = CGPoint(x: x, y: y)
            let endTickAt = CGPoint(x: timelineWidth + tickOverflow, y: y)
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
            var hour = firstHour + num
            var midday : String
            if hour > 12 {
                hour -= 12
                midday = "PM"
            } else {
                midday = "AM"
            }
            let str = NSAttributedString(string:(hour).description + midday, attributes: stringAttributes)
            let x : CGFloat = sidebarWidth / 2.0 - tickOverflow
            let y = CGFloat(num) * spacing + startOffset + lineWidth / 2
            let point = CGPoint(x: x, y: y - 4.0)
            str.draw(at: point)
        }
    }
    
    func drawSidebarLine() {
            
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        
        let startAt = CGPoint(x: sidebarWidth, y: 0)
        let endAt = CGPoint(x: sidebarWidth, y: self.frame.height)
        path.move(to: startAt)
        path.addLine(to: endAt)
        
        path.close()
        UIColor.lightGray.set()
        path.stroke()

    }
    
    func drawCurrentTime(spacing: CGFloat, tickWidth: CGFloat, timelineWidth: CGFloat) {
        
//        let path = UIBezierPath()
//        path.lineWidth = lineWidth
//        
//        let x = sidebarWidth - tickOverflow
//        let y = CGFloat(startTime.inHours()) * spacing
//        let startAt = CGPoint(x: x, y: y)
//        let endAt = CGPoint(x: tickWidth + tickOverflow, y: y)
//        path.move(to: startAt)
//        path.addLine(to: endAt)
//        
//        path.close()
//        UIColor.red.set()
//        path.stroke()
        
    }

    override func draw(_ rect: CGRect) {
        drawTicks(spacing: hourHeight, tickWidth: rect.width, timelineWidth: rect.width )
        drawNumbers(spacing: hourHeight)
        drawSidebarLine( )
        drawCurrentTime(spacing: hourHeight, tickWidth: rect.width, timelineWidth: rect.width)
    }

}
