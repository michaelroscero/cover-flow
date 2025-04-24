//
//  CoverFlowLayout.swift
//  ThreeDCoverFlow
//
//  Created by Michael Rosas Ceronio on 4/22/25.
//

import UIKit

class CoverFlowLayout: UICollectionViewFlowLayout {
    let activeDistance: CGFloat = 200  // How far the effect reaches from center
    let zoomFactor: CGFloat = 0.3      // Scale for center cell
    
    override func prepare() {
        super.prepare()
        scrollDirection = .horizontal
        minimumLineSpacing = -80  // Increased overlap
        itemSize = CGSize(width: 200, height: 300)
        
        // Center the cells in view
        let inset = (collectionView?.bounds.width ?? 0 - itemSize.width) / 2
        sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView,
              let attributes = super.layoutAttributesForElements(in: rect) else { return nil }

        let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2
        
        // Create a copy to avoid mutating shared layout
        let attributesCopy = attributes.map { $0.copy() as! UICollectionViewLayoutAttributes }

        for attr in attributesCopy {
            let distance = attr.center.x - centerX
            let normalizedDistance = distance / activeDistance
            
            if abs(distance) < activeDistance {
                let zoom = 1 + zoomFactor * (1 - pow(abs(normalizedDistance), 1.5))  // Smoother interpolation
                var rotationAngle: CGFloat
                let maxRotation: CGFloat = .pi / 4  // Max tilt: 45°

                if abs(distance) < activeDistance * 0.5 {
                    rotationAngle = -normalizedDistance * (.pi / 6)  // Smooth curve near center
                } else {
                    rotationAngle = normalizedDistance > 0 ? -maxRotation : maxRotation
                }

                var transform = CATransform3DIdentity
                transform.m34 = -1 / 500  // Adds depth perspective
                transform = CATransform3DScale(transform, zoom, zoom, 1.0)
                transform = CATransform3DRotate(transform, rotationAngle, 0, 1, 0)

                attr.transform3D = transform
                attr.zIndex = Int(zoom.rounded())

            
            } else {
                attr.transform3D = CATransform3DIdentity
                attr.zIndex = 0
            }
        }

        return attributesCopy
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }

        let targetRect = CGRect(origin: CGPoint(x: proposedContentOffset.x, y: 0), size: collectionView.bounds.size)
        guard let attributes = super.layoutAttributesForElements(in: targetRect) else { return proposedContentOffset }

        let centerX = proposedContentOffset.x + collectionView.bounds.width / 2
        let closest = attributes.min(by: { abs($0.center.x - centerX) < abs($1.center.x - centerX) }) ?? attributes[0]

        let newOffsetX = closest.center.x - collectionView.bounds.width / 2
        return CGPoint(x: newOffsetX, y: proposedContentOffset.y)
    }
}
