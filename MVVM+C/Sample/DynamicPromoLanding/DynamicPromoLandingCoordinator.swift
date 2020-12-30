//
//  DynamicPromoLandingCoordinator.swift
//  DynamicPromoLanding
//
//  Created by Yaroslav Magin on 28.10.2020.
//  Copyright © 2020 MTS Bank. All rights reserved.
//

import Coordinator
import Domain
import DynamicPromoLanding
import Foundation

final public class DynamicPromoLandingCoordinator: AssemblyCoordinator<DynamicPromoLandingResult> {
    
    weak var navigationController: UINavigationController?
    var openLink: ((URL) -> Void)?
    
    let landing: LandingData
    
    init(landing: Landing, navigationController: UINavigationController) {
        self.landing = LandingData(landing: landing)
        
        self.navigationController = navigationController
    }
    
    // MARK: - Lifecycle
    override public func assemblies() -> [Assembly] {
        return [
            DynamicPromoLandingModuleAssembly()
        ]
    }
    
    override public func start() {
        guard let module = resolver.resolve(DynamicPromoLandingModule.self, argument: landing) else {
            return
        }
        
        module.input.openLink = self.openLink
        
        module.output.onComplete = { [weak self] result in
            switch result {
            case .close:
                self?.onComplete?(.close)
            }
        }
        
        navigationController?.pushViewController(module.view, animated: true)
    }
}
