//
//  TimelineView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 08/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class TimelineView: UIView {
    
    var startHour : CGFloat = 12.0
    var hourHeight : CGFloat = 50.0
    var sidebarWidth : CGFloat = 50
    var currentHour : CGFloat = 1.0
    var timelineWidth : CGFloat!
    
    var startOffset : CGFloat {
        return 1 - startHour.truncatingRemainder(dividingBy: 1) * hourHeight
    }
    
    var numHourTicks : Int {
        let heightMinusOffset = self.frame.height - startOffset
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
    
    func drawTicks() {
        
        for tickNum in 0...(numHourTicks) {
            let x = sidebarWidth - tickOverflow
            let y = CGFloat(tickNum) * hourHeight + startOffset
            drawTick(minX: x, minY: y, color: UIColor.lightGray)
        }
        
    }
    
    func drawNumbers() {
        let firstHour = Int(ceil(startHour))
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
            let y = CGFloat(num) * hourHeight + startOffset + lineWidth / 2
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
    
    func drawTick(minX: CGFloat, minY: CGFloat, color: UIColor) {
        
        let tickPath = UIBezierPath()
        let width = timelineWidth + tickOverflow
        
        let startTickAt = CGPoint(x: minX, y: minY)
        let endTickAt = CGPoint(x: width, y: minY)
        tickPath.move(to: startTickAt)
        tickPath.addLine(to: endTickAt)
        
        color.set()
        tickPath.lineWidth = lineWidth
        tickPath.close()
        tickPath.stroke()
    }
    
    
    func drawCurrentTime() {
        
        let firstHour = startHour
        let lastHour = startHour + (self.frame.height / hourHeight)
        if (firstHour < currentHour) && (currentHour < lastHour) {
            let y = (currentHour - firstHour) * hourHeight
            drawTick(minX: 0, minY: y, color: UIColor.darkGray)
        }
        
    }

    override func draw(_ rect: CGRect) {
        timelineWidth = rect.width
        drawTicks()
        drawCurrentTime()
        drawNumbers()
        drawSidebarLine()
    }

}
