//
//  HoursCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 03/11/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class HoursCell: UICollectionViewCell {
    
    
//https://stackoverflow.com/questions/35750554/fill-a-uiview-with-diagonally-drawn-lines/45228178#45228178
    override func draw(_ rect: CGRect) {

        let T: CGFloat = 1     // desired thickness of lines
        let G: CGFloat = 4     // desired gap between lines
        let W = rect.size.width
        let H = rect.size.height

        guard let c = UIGraphicsGetCurrentContext() else { return }
        c.setStrokeColor(UIColor.black.withAlphaComponent(0.1).cgColor)
        c.setLineWidth(T)

        var p = -(W > H ? W : H) - T
        while p <= W {

            c.move( to: CGPoint(x: p-T, y: -T) )
            c.addLine( to: CGPoint(x: p+T+H, y: T+H) )
            c.strokePath()
            p += G + T + T
        }
    }
    
    func configureWith(_ place: Place) {
        backgroundColor = place.color.withAlphaComponent(0.1)
    }
    
}
