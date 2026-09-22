//
//  HabitListUITests.swift
//  MoldeaUITests
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import XCTest

final class HabitListUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Un hábito guardado desde la pantalla de creación aparece en la lista sin recargar nada.
    @MainActor
    func testCreatedHabitAppearsInTheList() throws {
        let app = XCUIApplication()
        // Base de datos en memoria e inglés, para no depender de datos previos ni del idioma del simulador.
        app.launchArguments += ["-inMemoryStore", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.tabBars.buttons["Habits"].tap()
        app.navigationBars.buttons["Add"].tap()

        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Beber agua")

        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Beber agua"].waitForExistence(timeout: 5))
        // Hábito diario de una sola repetición: el subtítulo es «Every day».
        XCTAssertTrue(app.staticTexts["Every day"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "habit-list"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
