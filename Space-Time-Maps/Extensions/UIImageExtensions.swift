import UIKit

extension UIImage {
    func rectToMaintainAspectRatio(for targetSize: CGSize, offset: CGPoint = CGPoint.zero) -> CGRect {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        let rectSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let wDiff = targetSize.width - rectSize.width
        let hDiff = targetSize.height - rectSize.height
        
        let rectOrigin = CGPoint(
            x: (wDiff > 0 ? wDiff / 2 : wDiff) + offset.x,
            y: (hDiff > 0 ? hDiff / 2 : hDiff) + offset.y
        )
        
        return CGRect(origin: rectOrigin, size: rectSize);
    }
}
