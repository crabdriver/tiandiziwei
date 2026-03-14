// ziweiApp.swift - 应用入口
// 紫微星语 iOS 版

import SwiftUI

@main
struct ziweiApp: App {
    @StateObject private var viewModel = ChartViewModel()
    
    var body: some Scene {
        WindowGroup {
            InputView(viewModel: viewModel)
        }
    }
}
