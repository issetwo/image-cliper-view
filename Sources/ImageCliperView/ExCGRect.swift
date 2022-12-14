//
//  ExCGRect.swift
//  issetwo swift library
//
//  Created by Kazuto Yamada on 2022/09/18.
//

import UIKit

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        let originX = center.x - size.width / 2.0
        let originY = center.y - size.height / 2.0
        self.init(x: originX, y: originY, width: size.width, height: size.height)
    }
}
