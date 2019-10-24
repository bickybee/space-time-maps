/// Copyright (c) 2018 Razeware LLC -> ray wenderlich

import UIKit

// The heights are declared as constants outside of the class so they can be easily referenced elsewhere
private struct LayoutConstants {
    struct Cell {
        // The height of the non-featured cell
        static let standardWidth: CGFloat = 30
        // The height of the first visible cell
        static let featuredWidth: CGFloat = 100
    }
}

// MARK: Properties and Variables

class OptionsLayout: UICollectionViewLayout {
    // The amount the user needs to scroll before the featured cell changes
    let dragOffset: CGFloat = 45
    
    var cache: [UICollectionViewLayoutAttributes] = []
    
    // Returns the item index of the currently featured cell
    var featuredItemIndex: Int {
        // Use max to make sure the featureItemIndex is never < 0
        return max(0, Int(  collectionView!.contentOffset.x / dragOffset))
    }
    
    // Returns a value between 0 and 1 that represents how close the next cell is to becoming the featured cell
    var nextItemPercentageOffset: CGFloat {
        return (collectionView!.contentOffset.x / dragOffset) - CGFloat(featuredItemIndex)
    }
    
    // Returns the width of the collection view
    var width: CGFloat {
        return collectionView!.bounds.width
    }
    
    // Returns the height of the collection view
    var height: CGFloat {
        return collectionView!.bounds.height
    }
    
    // Returns the number of items in the collection view
    var numberOfItems: Int {
        return collectionView!.numberOfItems(inSection: 0)
    }
}

// MARK: UICollectionViewLayout

extension OptionsLayout {
    // Return the size of all the content in the collection view
    override var collectionViewContentSize : CGSize {
        let contentWidth = (CGFloat(numberOfItems) * dragOffset) + (width - dragOffset)
        return CGSize(width: contentWidth, height: height)
    }
    
    override func prepare() {
        cache.removeAll(keepingCapacity: false)
        
        let standardWidth = LayoutConstants.Cell.standardWidth
        let featuredWidth = LayoutConstants.Cell.featuredWidth
        
        var frame = CGRect.zero
        var x: CGFloat = 0
        
        for item in 0 ..< numberOfItems {
            let indexPath = IndexPath(item: item, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.zIndex = indexPath.item
            // Initially set the height of the cell to the standard height
            var width = standardWidth
            if indexPath.item == featuredItemIndex {
                // The featured cell
                let xOffset = standardWidth * nextItemPercentageOffset
                x = collectionView!.contentOffset.x - xOffset
                width = featuredWidth
            } else if indexPath.item == (featuredItemIndex + 1) && indexPath.item != numberOfItems {
                // The cell directly below the featured cell, which grows as the user scrolls
                let maxX = x + standardWidth
                width = standardWidth + max((featuredWidth - standardWidth) * nextItemPercentageOffset, 0)
                x = maxX - width
            }
            frame = CGRect(x: x, y: 0, width: width, height: height)
            attributes.frame = frame
            cache.append(attributes)
            x = frame.maxX
        }
    }
    
    // Return all attributes in the cache whose frame intersects with the rect passed to the method
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes: [UICollectionViewLayoutAttributes] = []
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }
    
    // Return the content offset of the nearest cell which achieves the nice snapping effect, similar to a paged UIScrollView
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let itemIndex = round(proposedContentOffset.x / dragOffset)
        let xOffset = itemIndex * dragOffset
        return CGPoint(x: xOffset, y: 0)
    }
    
    // Return true so that the layout is continuously invalidated as the user scrolls
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
