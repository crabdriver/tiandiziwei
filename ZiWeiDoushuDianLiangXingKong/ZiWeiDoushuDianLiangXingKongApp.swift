// ZiWeiDoushuDianLiangXingKongApp.swift - 应用入口
// 紫微斗数-点亮星空版 iOS 版

import SwiftUI

@main
struct ZiWeiDoushuDianLiangXingKongApp: App {
    @StateObject private var viewModel = ChartViewModel()
    
    var body: some Scene {
        WindowGroup {
            InputView(viewModel: viewModel)
        }
    }
}
