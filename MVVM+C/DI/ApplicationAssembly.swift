//
//  ApplicationAssembley.swift
//  MVVM+C
//
//  Created by Максим Окунеев on 12/9/20.
//

import Foundation
import Swinject
import SwinjectStoryboard

final class ApplicationAssembly {

    // default dependencies
    static let assembler = Assembler(
        [
            FirstPageAssembly(),
            SecondPageAssembly(),
            ServiceAssembly()
//            ManagerAssembly()
        ]
    )
}
