//
//  ColorUtils.swift
//  Space-Time-Maps
//
//  Created by Vicky on 16/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import UIKit.UIColor

typealias UIColorGradient = (UIColor, UIColor)

class ColorUtils {
    
    static private var usedColors = 0;
    static private let colors = [
        UIColor(red: 0.72, green: 0.00, blue: 0.00, alpha: 1.00),
        UIColor(red: 0.86, green: 0.50, blue: 0.00, alpha: 1.00),
        UIColor(red: 0.99, green: 0.80, blue: 0.00, alpha: 1.00),
        UIColor(red: 0.59, green: 0.59, blue: 0.27, alpha: 1.00),
        UIColor(red: 0.00, green: 0.55, blue: 0.01, alpha: 1.00),
        UIColor(red: 0.00, green: 0.42, blue: 0.46, alpha: 1.00),
        UIColor(red: 0.07, green: 0.45, blue: 0.87, alpha: 1.00),
        UIColor(red: 0.00, green: 0.30, blue: 0.81, alpha: 1.00),
        UIColor(red: 0.33, green: 0.00, blue: 0.92, alpha: 1.00)
    ]
    
    static func randomColor() -> UIColor {
        let color = colors[usedColors % colors.count]
        usedColors += 1
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
    
    static func colorWithGradient(frame: CGRect, colors: [UIColor]) -> UIColor? {
        
        // create the background layer that will hold the gradient
        let backgroundGradientLayer = CAGradientLayer()
        backgroundGradientLayer.frame = frame
         
        // we create an array of CG colors from out UIColor array
        let cgColors = colors.map({$0.cgColor})
        
        backgroundGradientLayer.colors = cgColors
        
        UIGraphicsBeginImageContext(backgroundGradientLayer.bounds.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        backgroundGradientLayer.render(in: context)
        guard let backgroundColorImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return UIColor(patternImage: backgroundColorImage)
    }

}
