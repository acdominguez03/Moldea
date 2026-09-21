//
//  HabitPaletteColor.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI
import Core

enum HabitPaletteColor: CaseIterable, Identifiable {
    case red
    case orange
    case yellow
    case green
    case mint
    case teal
    case blue
    case indigo
    case purple
    case pink
    case gray
    case brown
    case stone

    var id: Self { self }

    /// Hex `#RRGGBB`: es lo que se guarda en el hábito.
    var hex: String {
        switch self {
        case .red: "#C8372D"
        case .orange: "#D4762A"
        case .yellow: "#C9A227"
        case .green: "#6E9440"
        case .mint: "#3E8E7E"
        case .teal: "#2E7D8F"
        case .blue: "#3A6BC6"
        case .indigo: "#6C5BC4"
        case .purple: "#9B4B8C"
        case .pink: "#B0556B"
        case .gray: "#5B6470"
        case .brown: "#8A6A4F"
        case .stone: "#DAD7D0"
        }
    }

    /// El fallback es una red de seguridad: `HabitPaletteColorTests` garantiza que todos los hex parsean.
    var color: Color {
        HexColorConverter.color(fromHex: hex) ?? .gray
    }

    var name: LocalizedStringResource {
        switch self {
        case .red: HabitsTextsEnum.colorRed
        case .orange: HabitsTextsEnum.colorOrange
        case .yellow: HabitsTextsEnum.colorYellow
        case .green: HabitsTextsEnum.colorGreen
        case .mint: HabitsTextsEnum.colorMint
        case .teal: HabitsTextsEnum.colorTeal
        case .blue: HabitsTextsEnum.colorBlue
        case .indigo: HabitsTextsEnum.colorIndigo
        case .purple: HabitsTextsEnum.colorPurple
        case .pink: HabitsTextsEnum.colorPink
        case .gray: HabitsTextsEnum.colorGray
        case .brown: HabitsTextsEnum.colorBrown
        case .stone: HabitsTextsEnum.colorStone
        }
    }
}
