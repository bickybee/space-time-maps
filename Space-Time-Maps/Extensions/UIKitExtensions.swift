//
//  UIKitExtensions.swift
//  Space-Time-Maps
//
//  Created by Vicky on 24/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

@nonobjc extension UIViewController {
    func add(_ child: UIViewController, frame: CGRect? = nil) {
        addChild(child)
        
        if let frame = frame {
            child.view.frame = frame
        }
        
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

extension UIButton {
    
    func toggle() {
        
        self.isEnabled = !self.isEnabled
        self.alpha = self.isEnabled ? 1.0 : 0.0
        
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
