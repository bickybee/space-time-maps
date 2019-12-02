//
//  ItineraryLayout.swift
//  Space-Time-Maps
//
//  Created by Vicky on 09/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class ItineraryLayout: UICollectionViewLayout {
    
    weak var delegate: ItineraryLayoutDelegate!
    var shouldPadCells: Bool = true

    fileprivate var cache = [UICollectionViewLayoutAttributes]()
    fileprivate var contentHeight: CGFloat = 0
    
    fileprivate var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.bounds.width
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height:contentHeight)
    }
    
    override func prepare() {
        super.prepare()
        cache.removeAll()
        
        guard let collectionView = collectionView else { return }
        
        for section in 0 ... collectionView.numberOfSections - 1 {
            for item in 0 ..< collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                cacheAttributesForCellAt(indexPath: indexPath, in: collectionView)
            }
        }
    }
    
    func cacheAttributesForCellAt(indexPath: IndexPath, in collectionView: UICollectionView) {
        
        if indexPath.section == 3 {
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let hourHeight = delegate.hourHeight(of: collectionView)
            attributes.frame = CGRect(x: 0, y: 0, width: contentWidth, height: 24.5 * hourHeight)
            attributes.zIndex = -10
            cache.append(attributes)
            contentHeight = 24.5 * hourHeight 
        } else {
            
            // Get data from delegate
            let eventTiming = delegate.collectionView(collectionView, timingForEventAtIndexPath: indexPath)
            let hourHeight = delegate.hourHeight(of: collectionView)
            let minX = delegate.timelineSidebarWidth(of: collectionView)
            
            let startHour = eventTiming.start.inHours()
            let duration = eventTiming.duration.inHours()
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            
            // Always true
            let height = CGFloat(duration) * hourHeight
            let relativeHour = CGFloat(startHour)
            let y = relativeHour * hourHeight
            
            // Depends on the cell/settings...
            var width = contentWidth - minX
            var x: CGFloat = minX
            
            if indexPath.section >= 2 {
                attributes.zIndex = -1
            }
            
            else if shouldPadCells {
                width = contentWidth * 0.8 - minX
                x += contentWidth * 0.1
            }
            
            let frame = CGRect(x: x, y: y, width: width, height: height)
            
            // Add to cache
            attributes.frame = frame
            cache.append(attributes)
            // Update content height
    //        contentHeight = max(contentHeight, frame.maxY)
    
        }

    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
        
        // Loop through the cache and look for items in the rect
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache.first(where: { $0.indexPath == indexPath })
    }
    
}

protocol ItineraryLayoutDelegate: AnyObject {
    func timelineSidebarWidth(of collectionView: UICollectionView) -> CGFloat
    func hourHeight(of collectionView: UICollectionView) -> CGFloat
    func collectionView(_ collectionView:UICollectionView, timingForEventAtIndexPath indexPath: IndexPath) -> Timing
}
