//
//  MissingDependenciesView.swift
//  Core
//

import SwiftUI

public struct MissingDependenciesView: View {
    private let typeName: String

    public init(_ type: Any.Type) {
        typeName = String(describing: type)
    }

    public var body: some View {
        let _ = assertionFailure("\(typeName) is not injected in the environment")
        EmptyView()
    }
}
