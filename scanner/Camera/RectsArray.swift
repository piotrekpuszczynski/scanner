//
//  RectsArray.swift
//

import Foundation

class RectsArray {
    private var rects = Array<CGRect>()
    private let offset = 0.01
    
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
}

extension CGRect {
    func mergable(_ rect: CGRect, offset: CGFloat) -> Bool {
        if intersects(rect) { return true }
        
        let leftRectX = min(self.minX, rect.minX)
        let upperRectY = min(self.minY, rect.minY)
        if minX - rect.minX < offset || minY - minY < offset {
            return true
        }
        return false
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
