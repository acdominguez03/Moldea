//
//  AppGroup.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import Foundation

public enum AppGroup {
    public static let identifier = "group.com.cordondevs.moldea"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
