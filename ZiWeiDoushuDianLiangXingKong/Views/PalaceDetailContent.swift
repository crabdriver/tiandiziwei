// PalaceDetailContent.swift - 单宫详情（盘面点击与列表复用）

import SwiftUI

/// 十二宫中某一宫的完整信息块（与「排盘详情」列表一致）
struct PalaceDetailContent: View {
    let palace: Palace

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(palace.name)
                    .font(.headline)
                    .foregroundColor(ZiWeiColors.gongNameColor)

                Text("(\(palace.tianGan)\(palace.position))")
                    .foregroundColor(.secondary)

                Spacer()

                if !palace.daXian.isEmpty {
                    Text("大限: \(palace.daXian)")
                        .font(.caption)
                        .foregroundColor(ZiWeiColors.daXianColor)
                }
            }

            HStack {
                Text("长生: \(palace.changSheng)")
                Spacer()
                Text("岁前: \(palace.suiQian)")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            HStack {
                Text("将前: \(palace.jiangQian)")
                Spacer()
                Text("博士: \(palace.boshi)")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if !palace.xiaoXian.isEmpty {
                Text("小限: \(palace.xiaoXian)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !palace.gongTransforms.isEmpty {
                transformSection(title: "宫干四化", transforms: palace.gongTransforms)
            }

            if !palace.chongHua.isEmpty {
                transformSection(title: "冲化", transforms: palace.chongHua)
            }

            if !palace.ziHua.isEmpty {
                transformSection(title: "自化", transforms: palace.ziHua)
            }

            FlowLayout(spacing: 6) {
                ForEach(palace.stars, id: \.name) { star in
                    HStack(spacing: 2) {
                        Text(star.name)
                            .font(.caption)
                            .foregroundColor(ChartPalette.starColor(star))
                        if let hua = star.siHua {
                            Text(ChartPalette.huaShortText(hua))
                                .font(.caption2)
                                .foregroundColor(ChartPalette.huaColor(hua))
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ZiWeiColors.cardSurface.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(ZiWeiColors.border.opacity(0.45), lineWidth: 0.5)
                    )
                    .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func transformSection(title: String, transforms: [PalaceTransform]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(Array(transforms.enumerated()), id: \.offset) { _, transform in
                HStack {
                    Text("\(transform.star)\(ChartPalette.huaShortText(transform.hua))")
                        .foregroundColor(ChartPalette.huaColor(transform.hua))
                    Spacer()
                    Text("\(transform.targetPalace)-\(transform.targetPosition)")
                        .foregroundColor(.secondary)
                    Text("\(transform.strength)%")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
    }
}
