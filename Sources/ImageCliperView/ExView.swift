//
//  ExView.swift
//  issetwo swift library
//
//  Created by Kazuto Yamada on 2022/08/13.
//

import SwiftUI

@available(iOS 15.0, *)
extension View {
    
    /// スナップショット画像取得
    /// - Returns: 画像
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    /// 逆マスク
    /// - Returns: ビュー
    func reverseMask<Mask: View>(alignment: Alignment = .center,
                                 @ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask()
                        .blendMode(.destinationOut)
                }
               // .compositingGroup() 無くても機能する
        }
    }
}
