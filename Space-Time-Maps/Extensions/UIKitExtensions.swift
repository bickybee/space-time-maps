//
//  UIButtonExtensions.swift
//  Space-Time-Maps
//
//  Created by Vicky on 02/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import UIKit.UIButton

extension UIButton {
    
    func toggle() {
        
        self.isEnabled = !self.isEnabled
        self.alpha = self.isEnabled ? 1.0 : 0.0
        
    }
    
}

extension UIView {
    
    /// Create image snapshot of view.
    ///
    /// - Parameters:
    ///   - rect: The coordinates (in the view's own coordinate space) to be captured. If omitted, the entire `bounds` will be captured.
    ///   - afterScreenUpdates: A Boolean value that indicates whether the snapshot should be rendered after recent changes have been incorporated. Specify the value false if you want to render a snapshot in the view hierarchy’s current state, which might not include recent changes. Defaults to `true`.
    ///
    /// - Returns: The `UIImage` snapshot.
    
    func snapshot(of rect: CGRect? = nil, afterScreenUpdates: Bool = true) -> UIImage {
        return UIGraphicsImageRenderer(bounds: rect ?? bounds).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
        }
    }
}

extension UICollectionView {
    func scrollToNearestVisibleCollectionViewCell() {
        guard let centerCellIndex = getCenterCellIndex() else { return }
        
        self.decelerationRate = UIScrollView.DecelerationRate.fast
        self.scrollToItem(at: IndexPath(row: centerCellIndex, section: 0), at: .centeredHorizontally, animated: true)
        
    }
    
    func getCenterCellIndex() -> Int? {
        
        let visibleCenterPositionOfScrollView = Float(self.contentOffset.x + (self.bounds.size.width / 2))
        var closestCellIndex : Int?
        var closestDistance: Float = .greatestFiniteMagnitude
        for i in 0..<self.visibleCells.count {
            let cell = self.visibleCells[i]
            let cellWidth = cell.bounds.size.width
            let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)
            
            // Now calculate closest cell
            let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
            if distance < closestDistance {
                closestDistance = distance
                closestCellIndex = self.indexPath(for: cell)!.row
            }
        }
        
        return closestCellIndex
        
    }
    
}
