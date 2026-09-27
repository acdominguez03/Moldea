//
//  HabitPaletteIconEnum.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import Foundation

enum HabitPaletteIconEnum: String, CaseIterable, Identifiable {
    case drop
    case book
    case bolt
    case tree
    case dumbbell
    case musicNote = "music.note"
    case pill
    case phone
    case cupAndSaucer = "cup.and.saucer"
    case sunMax = "sun.max"
    case moon
    case heart
    case calendar

    var id: Self { self }

    var systemName: String { rawValue }

    var name: LocalizedStringResource {
        switch self {
        case .drop: HabitsTextsEnum.iconDrop
        case .book: HabitsTextsEnum.iconBook
        case .bolt: HabitsTextsEnum.iconBolt
        case .tree: HabitsTextsEnum.iconTree
        case .dumbbell: HabitsTextsEnum.iconDumbbell
        case .musicNote: HabitsTextsEnum.iconMusicNote
        case .pill: HabitsTextsEnum.iconPill
        case .phone: HabitsTextsEnum.iconPhone
        case .cupAndSaucer: HabitsTextsEnum.iconCupAndSaucer
        case .sunMax: HabitsTextsEnum.iconSunMax
        case .moon: HabitsTextsEnum.iconMoon
        case .heart: HabitsTextsEnum.iconHeart
        case .calendar: HabitsTextsEnum.iconCalendar
        }
    }
}
