//
//  HabitPaletteColor.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI

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
    case brown
    case gray
    case black

    var id: Self { self }

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .brown: .brown
        case .gray: .gray
        case .black: .black
        }
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
        case .brown: HabitsTextsEnum.colorBrown
        case .gray: HabitsTextsEnum.colorGray
        case .black: HabitsTextsEnum.colorBlack
        }
    }
}
