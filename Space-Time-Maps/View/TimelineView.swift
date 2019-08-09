//
//  TimelineView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 08/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class TimelineView: UIView {
    
    var numTicks : Int = 12
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
        
        for tickNum in 0...numTicks {
            let y = CGFloat(tickNum + 1) * spacing - (lineWidth / 2)
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
        for num in 0...numTicks {
            let str = NSAttributedString(string: (num + 1).description + ":00", attributes: stringAttributes)
            let x : CGFloat = 0
            let y = CGFloat(num + 1) * spacing - (spacing / 3)
            let point = CGPoint(x: x, y: y)
            str.draw(at: point)
        }
    }

    override func draw(_ rect: CGRect) {
        let tickSpacing = rect.height / CGFloat(numTicks)
        
        drawTicks(spacing: tickSpacing, width: rect.width)
        drawNumbers(spacing: tickSpacing)
    }

}
