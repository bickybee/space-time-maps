//
//  TimelineView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 08/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class TimelineView: UIView {
    
    private let numTicks : Int = 12
    private let lineWidth : CGFloat = 2
    
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

    override func draw(_ rect: CGRect) {
        let height = rect.height
        let width = rect.width
        
        let tickSpacing = height / CGFloat(numTicks)
        
        let tickPath = UIBezierPath()
        tickPath.lineWidth = lineWidth
        
        for tickNum in 0...numTicks {
            let y = CGFloat(tickNum + 1) * tickSpacing - (lineWidth / 2)
            let startTickAt = CGPoint(x: 0, y: y)
            let endTickAt = CGPoint(x: width, y: y)
            tickPath.move(to: startTickAt)
            tickPath.addLine(to: endTickAt)
        }
        
        tickPath.close()
        UIColor.blue.set()
        tickPath.stroke()
    }

}
