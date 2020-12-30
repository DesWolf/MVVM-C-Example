//
//  ServiceAssembly.swift
//  MVVM+C
//
//  Created by Максим Окунеев on 12/18/20.
//

import Foundation
import Swinject

struct ServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ModuleAssemblyType.self) { r in ModuleAssembly(resolver: r) }.inObjectScope(.container)
        
        container.register(FirstPageData.self) { _ in FirstPageData() }.inObjectScope(.container)
        container.register(SecondPageData.self) { _ in SecondPageData() }.inObjectScope(.container)
    }
}
