//
//  ColorUtils.swift
//  Space-Time-Maps
//
//  Created by Vicky on 16/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import UIKit.UIColor
import ChameleonFramework

typealias UIColorGradient = (UIColor, UIColor)


class ColorUtils {
    
    static private var usedColors = [UIColor]()
    
    static func randomColor() -> UIColor {
        let color = RandomFlatColorWithShade(.dark)
        
        if usedColors.contains(color) {
            return randomColor()
        }
        
        usedColors.append(color)
        
        // Used up all the colors? allow repeats now...
        if usedColors.count == 12 {
            usedColors = [UIColor]()
        }
        
        return color
    }

    // Point along 3-color gradient
    static func colorAlongGradient(start: UIColor, middle: UIColor, end: UIColor, fraction: CGFloat) -> UIColor {

        guard (0 <= fraction) && (fraction <= 1) else { return start }

        if fraction < 0.5 {
            return colorAlongGradient(start: start, end: middle, fraction: fraction / 0.5)
        } else {
            return colorAlongGradient(start: middle, end: end, fraction: (fraction - 0.5) / 0.5)
        }

    }

    // Point along 2-color gradient
    static func colorAlongGradient(start: UIColor, end: UIColor, fraction: CGFloat) -> UIColor {

        guard (0 <= fraction) && (fraction <= 1) else { return start }

        // Get color components
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        guard start.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return start }
        guard end.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return start }

        // Return color along gradient
        return UIColor(red: CGFloat(r1 + (r2 - r1) * fraction),
                       green: CGFloat(g1 + (g2 - g1) * fraction),
                       blue: CGFloat(b1 + (b2 - b1) * fraction),
                       alpha: CGFloat(a1 + (a2 - a1) * fraction))

    }

}
