//
//  TimelineView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 08/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class TimelineView: UIView {
    
    var startTime : Double = 0.25 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    var hourHeight : CGFloat = 50 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var startOffset : CGFloat {
        return CGFloat(1 - startTime.truncatingRemainder(dividingBy: 1)) * hourHeight
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
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 7.0),
        NSAttributedString.Key.foregroundColor: UIColor.blue
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
        self.backgroundColor = UIColor.blue.withAlphaComponent(0.2)
    }
    
    func drawTicks(spacing: CGFloat, width: CGFloat) {
        
        let tickPath = UIBezierPath()
        tickPath.lineWidth = lineWidth
        
        for tickNum in 0...numHourTicks {
            let y = CGFloat(tickNum) * spacing + startOffset
            let startTickAt = CGPoint(x: 0, y: y)
            let endTickAt = CGPoint(x: width, y: y)
            tickPath.move(to: startTickAt)
            tickPath.addLine(to: endTickAt)
        }
        
        tickPath.close()
        UIColor.blue.set()
        tickPath.stroke()
        
    }
    
    func drawNumbers(spacing: CGFloat) {
        let firstHour = Int(ceil(startTime))
        for num in 0...numHourTicks {
            let str = NSAttributedString(string: (firstHour + num).description + ":00", attributes: stringAttributes)
            let x : CGFloat = 0
            let y = CGFloat(num) * spacing - (spacing / 4) + startOffset
            let point = CGPoint(x: x, y: y)
            str.draw(at: point)
        }
    }

    override func draw(_ rect: CGRect) {
        drawTicks(spacing: hourHeight, width: rect.width)
        drawNumbers(spacing: hourHeight)
    }

}
