// ZiWeiDoushuDianLiangXingKongApp.swift - 应用入口
// 看盘啦 · iOS 紫微斗数排盘

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
