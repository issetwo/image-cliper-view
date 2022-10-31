//
//  ExUIImage.swift
//  issetwo swift library
//
//  Created by Kazuto Yamada on 2022/07/24.
//

import Foundation
import UIKit

extension UIImage {
    public convenience init(filePath: String) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            self.init(data: data)!
            return
        } catch let err {
            print("Error : \(err.localizedDescription)")
        }
        self.init()
    }
    
    /// 画像の回転
    /// - Parameter radians: ラジアン
    /// - Returns: 回転した画像
    func rotated(by radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size

        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, scale)
        if let context = UIGraphicsGetCurrentContext(), let cgImage = cgImage {
            context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.rotate(by: radians)
            context.scaleBy(x: 1, y: -1)
            context.translateBy(x: -size.width / 2, y: -size.height / 2)
            context.draw(cgImage, in: .init(origin: .zero, size: size))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return rotatedImage ?? self
        }
        return self
    }
}
