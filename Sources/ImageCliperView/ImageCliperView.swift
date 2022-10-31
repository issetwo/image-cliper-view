//
//  ImageCliperView.swift
//  ImageCliperView
//
//  Created by Kazuto Yamada on 2022/08/06.
//

import SwiftUI

// 定数定義
private let kOffset: CGSize = .zero             // オフセット位置のデフォルト値
private let kScale: CGFloat = 1.0               // スケール値のデフォルト値
private let kMaxScale: CGFloat = 3.0            // 最大スケール値
private let kRotation: Double = 0.0             // 角度のデフォルト値
private let kUnitRotation: Double = 90.0        // 角度の単位
private let kCancelString: String = "Cancel"    // キャンセルボタンのデフォルト文字列
private let kApplyString: String = "Apply"      // 適用ボタンのデフォルト文字列
private let kBackOpacity: CGFloat = 0.5         // 背景の透明度のデフォルト値

/// 画像クリッピングビュー
@available(iOS 15.0, *)
struct ImageCliperView: View {
    @Environment(\.presentationMode) var presentationMode
    // データバインド
    @Binding var image: UIImage?                        // クリップした画像
    // 内部ステータス用変数
    @State private var offset: CGSize = kOffset         // オフセット値（移動中）
    @State private var initialOffset: CGSize = kOffset  // オフセット値（確定）
    @State private var scale: CGFloat = kScale          // スケール値（スケーリング中）
    @State private var initialScale: CGFloat = kScale   // スケール値（確定）
    @State private var rotation: Double = kRotation     // 角度
    // 内部変数
    private var clipSize: CGSize = .zero                // 切り抜きサイズ
    private var clipRect: CGRect {                      // 切り抜きの領域
        get {
            return CGRect(center: CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY), size: self.clipSize)
        }
    }
    private var imageSize: CGSize = .zero               // 画像のサイズ
    private var imageRect: CGRect {                     // 画像の領域
        get {
            return CGRect(center: CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY), size: self.imageSize)
        }
    }
    private var maxScale: CGFloat = kMaxScale            // スケール値（最大スケール値）※1以下の場合は制限なし
    private var cancelString: String = kCancelString     // キャンセル文字列
    private var applyString: String = kApplyString       // 適用文字列

    // 初期化
    init(image: Binding<UIImage?>,
         cancelString: String = kCancelString,
         applyString: String = kApplyString,
         maxScale: CGFloat = kMaxScale) {
        self._image = image
        self.maxScale = maxScale
        self.cancelString = cancelString
        self.applyString = applyString
        // クリップの領域算出
        let clipWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 60
        self.clipSize = CGSize(width: clipWidth, height: clipWidth)
        // 画像の領域算出
        let size = self.image!.size
        var width = 0.0
        var height = 0.0
        if size.width < size.height {
            let ratio = size.height / size.width
            width = self.clipSize.width
            height = width * ratio
        }
        else {
            let ratio = size.width / size.height
            height = self.clipSize.width
            width = height * ratio
        }
        self.imageSize = CGSize(width: width, height: height)
    }
        
    // 画像表示用ビュー
    private var imageView: some View {
        VStack {
            Image(uiImage: image ?? UIImage())
                .resizable()
                .frame(width: self.imageSize.width, height: self.imageSize.height, alignment: .center)
                .rotationEffect(.degrees(self.rotation)) // 右にrotationの角度分回転
                .offset(self.offset)
                .scaleEffect(self.scale)
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // クリップ表示ビュー
    private var clipView: some View {
        // 画像を拡大・縮小するためのジェスチャー定義
        let magnificationGesture = MagnificationGesture()
            .onChanged {
                var newScale = $0 * initialScale
                if kScale <= self.maxScale {
                    if newScale > self.maxScale {
                        newScale = self.maxScale
                    }
                }
                scale = ajustScale(scale: newScale)
                //print(scale)
            }
            .onEnded{ _ in
                initialScale = scale
            }
        // ドラッグ移動するためのジェスチャー定義
        let dragGesture = DragGesture()
            .onChanged {
                let newWidth = initialOffset.width + $0.translation.width / self.scale
                let newHeight = initialOffset.height + $0.translation.height / self.scale
                offset = ajustOffset(offset: CGSize(width: newWidth, height: newHeight))
                //print(offset)
            }
            .onEnded{ _ in
                initialOffset = offset
            }

        return Color.black
            .opacity(kBackOpacity)
            .reverseMask({
                Circle()
                    .frame(width: self.clipSize.width, height: self.clipSize.height, alignment: .center)
            })
            .gesture(dragGesture)
            .gesture(magnificationGesture)
    }

    // 本体ビュー
    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    self.imageView
                    self.clipView
                }
                .edgesIgnoringSafeArea(.all)
            }
            // ツールバー設定
            .toolbar{
                // 左上アイコン：キャンセル
                ToolbarItem(placement: .navigationBarLeading){
                    Button(action: {
                        onCancel()
                    }) {
                        Text(self.cancelString)
                    }
                }
                // 右上アイコン：適用ボタン
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        onApply()
                    }) {
                        Text(self.applyString)
                            .bold()
                    }
                }
                // ボトムバー
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    // 回転ボタン
                    Button(action: {
                        withAnimation {
                            onRotation()
                        }
                    }) {
                        Image(systemName: "rotate.right")
                    }
                    Spacer()
                }
            }
        }
        .accentColor(Color("Accent"))
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    /// キャンセル
    private func onCancel() {
        // キャンセルを判断するために nil を代入
        self.image = nil
        // 画面を閉じる
        self.presentationMode.wrappedValue.dismiss()
    }

    /// 適用
    private func onApply() {
        // クリップした画像を取得
        self.image = self.imageView.snapshot()
        // 画面を閉じる
        self.presentationMode.wrappedValue.dismiss()
    }
    
    /// 回転
    private func onRotation() {
        // 右に90度回転
        self.rotation += 90
        // オフセット位置の補正
        self.offset = ajustOffset(offset: self.initialOffset)
    }
    
    /// スケールの調整
    /// - Parameter scale: スケール値
    /// - Returns: 調整したスケール値
    private func ajustScale(scale: CGFloat) -> CGFloat {
        // ローテーションを加味した画像領域を取得
        let imageRect = rotationImageRect()
        // 現在のスケールを加味した画像領域を取得
        let newWidth = imageRect.width * scale
        let newHeight = imageRect.height * scale
        let newX = imageRect.midX - newWidth / 2
        let newY = imageRect.midY - newHeight / 2
        let scalingImageRect = CGRect(origin: CGPoint(x: newX, y: newY), size: CGSize(width: newWidth, height: newHeight))
        //print(scalingImageRect)
        // 画像領域をオフセット移動した領域を取得
        let offsetedImageRect = scalingImageRect.offsetBy(dx: self.offset.width * scale, dy: self.offset.height * scale)
        //print(offsetedImageRect)
        var resultScale = scale
        // クリップする領域をオーバーした場合
        if offsetedImageRect.contains(self.clipRect) == false {
            resultScale = self.scale
        }
        return resultScale
    }
    
    /// オフセットサイズの調整
    /// - Parameter offset: オフセットサイズ
    /// - Returns: 調整したオフセットサイズ
    private func ajustOffset(offset: CGSize) -> CGSize {
        // ローテーションを加味した画像領域を取得
        let imageRect = rotationImageRect()
        // 現在のスケールを加味した画像領域を取得
        let newWidth = imageRect.width * self.scale
        let newHeight = imageRect.height * self.scale
        let newX = imageRect.midX - newWidth / 2
        let newY = imageRect.midY - newHeight / 2
        let scalingImageRect = CGRect(origin: CGPoint(x: newX, y: newY), size: CGSize(width: newWidth, height: newHeight))
        //print(scalingImageRect)
        // 現在のスケールを加味したオフセットサイズを取得
        let scalingOffset = CGSize(width: offset.width * self.scale, height: offset.height * self.scale)
        // 画像領域をオフセット移動した領域を取得
        let offsetedImageRect = scalingImageRect.offsetBy(dx: scalingOffset.width, dy: scalingOffset.height)
        //print(offsetedImageRect)
        var resultOffset = offset
        // クリップする領域をオーバーした場合（左）
        if self.clipRect.minX < offsetedImageRect.minX {
            // 左部最大領域計算
            let diff = offsetedImageRect.minX - self.clipRect.minX
            let width = ( scalingOffset.width - diff ) / self.scale
            // オフセット位置補正
            resultOffset = CGSize(width: width, height: resultOffset.height)
        }
        // クリップする領域をオーバーした場合（右）
        if offsetedImageRect.maxX < self.clipRect.maxX {
            // 右部最大領域計算
            let diff = offsetedImageRect.maxX - self.clipRect.maxX
            let width = ( scalingOffset.width - diff ) / self.scale
            // オフセット位置補正
            resultOffset = CGSize(width: width, height: resultOffset.height)
        }
        // クリップする領域をオーバーした場合（上）
        if self.clipRect.minY < offsetedImageRect.minY {
            // 上部最大領域計算
            let diff = offsetedImageRect.minY - self.clipRect.minY
            let height = ( scalingOffset.height - diff ) / self.scale
            // オフセット位置補正
            resultOffset = CGSize(width: resultOffset.width, height: height)
        }
        // クリップする領域をオーバーした場合（下）
        if offsetedImageRect.maxY < self.clipRect.maxY {
            // 下部最大領域計算
            let diff = offsetedImageRect.maxY - self.clipRect.maxY
            let height = ( scalingOffset.height - diff ) / self.scale
            // オフセット位置補正
            resultOffset = CGSize(width: resultOffset.width, height: height)
        }
        
        return resultOffset
    }
    
    /// ローテーションを加味した画像領域を取得
    /// - Returns: ローテーションを加味した画像領域
    private func rotationImageRect() -> CGRect {
        var imageRect = self.imageRect
        let rocationCount = Int(self.rotation / 90)
        let direction = rocationCount % 4
        if direction == 1 || direction == 3 {
            imageRect = CGRect(center: CGPoint(x: self.imageRect.midX, y: self.imageRect.midY), size: CGSize(width: self.imageRect.height, height: self.imageRect.width))
        }
        return imageRect
    }
    
}
