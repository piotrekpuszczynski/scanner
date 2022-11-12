//
//  RectsArray.swift
//

import Foundation

class RectsArray {
    private var rects = Array<CGRect>()
    private let offset = 0.05
    
    func append(_ new: CGRect) {
        for i in rects.indices {
            if rects[i].mergable(new, offset: offset) {
                rects[i] = rects[i].merge(new)
                return
            }
        }
        rects.append(new)
    }
    
    func getBiggest() -> CGRect? {
        if rects.isEmpty { return nil }

        let blockAcs = rects.sorted { first, second in
            first.area() > second.area()
        }

        return blockAcs.first
    }
    
    func clear() {
        rects.removeAll()
    }
}

extension CGRect {
    func mergable(_ rect: CGRect, offset: CGFloat) -> Bool {
        if intersects(rect) { return true }

//        if distance(to: rect) < offset { return true }
        return false
    }
    
    func distance(to rect: CGRect) -> CGFloat {
        let left = rect.maxX < minX
        let right = maxX < rect.minX
        let bottom = rect.maxY < minY
        let top = maxY < rect.minY
        if top && left {
            return CGPointDistanceSquared(from: CGPoint(x: minX, y: maxY), to: CGPoint(x: rect.maxX, y: rect.minY))
        } else if left && bottom {
            return CGPointDistanceSquared(from: CGPoint(x: minX, y: minY), to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else if bottom && right {
            return CGPointDistanceSquared(from: CGPoint(x: maxX, y: minY), to: CGPoint(x: rect.minX, y: rect.maxY))
        } else if right && top {
            return CGPointDistanceSquared(from: CGPoint(x: maxX, y: maxY), to: CGPoint(x: rect.minX, y: rect.minY))
        } else if left {
            return minX - rect.maxX
        } else if right {
            return rect.minX - maxX
        } else if bottom {
            return minY - rect.maxY
        } else if top {
            return rect.minY - maxY
        } else {
            return 0
        }
    }

    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

    func merge(_ rect: CGRect) -> CGRect {
        let x = min(self.minX, rect.minX)
        let y = min(self.minY, rect.minY)
        let width = rect.minX + rect.width - self.minX
        let height = max(self.minY + self.height, rect.minY + rect.height) - y
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func area() -> CGFloat {
        return self.height * self.width
    }
}
