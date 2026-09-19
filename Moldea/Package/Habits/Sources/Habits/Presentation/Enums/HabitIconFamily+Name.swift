//
//  HabitIconFamily+Name.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import Foundation

extension HabitIconFamily {
    var name: LocalizedStringResource {
        switch key {
        case "fitness": HabitsTextsEnum.iconFamilyFitness
        case "health": HabitsTextsEnum.iconFamilyHealth
        case "nature": HabitsTextsEnum.iconFamilyNature
        case "weather": HabitsTextsEnum.iconFamilyWeather
        case "home": HabitsTextsEnum.iconFamilyHome
        case "time": HabitsTextsEnum.iconFamilyTime
        case "objectsandtools": HabitsTextsEnum.iconFamilyObjectsAndTools
        case "human": HabitsTextsEnum.iconFamilyHuman
        case "communication": HabitsTextsEnum.iconFamilyCommunication
        case "commerce": HabitsTextsEnum.iconFamilyCommerce
        case "media": HabitsTextsEnum.iconFamilyMedia
        case "transportation": HabitsTextsEnum.iconFamilyTransportation
        case "maps": HabitsTextsEnum.iconFamilyMaps
        case "gaming": HabitsTextsEnum.iconFamilyGaming
        case "cameraandphotos": HabitsTextsEnum.iconFamilyCameraAndPhotos
        default: HabitsTextsEnum.iconFamilyOther
        }
    }
}
