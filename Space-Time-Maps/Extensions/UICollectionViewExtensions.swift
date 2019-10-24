//
//  UICollectionViewExtensions.swift
//  Space-Time-Maps
//
//  Created by Vicky on 24/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import UIKit

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
