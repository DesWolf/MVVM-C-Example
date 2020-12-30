//
//  DynamicPromoLandingModule.swift
//  Pods
//
//  Created by Yaroslav Magin on 24/10/2020.
//  Copyright © 2020 MTS Bank. All rights reserved.
//

import Domain
import Foundation

import FeatureModule

public protocol DynamicPromoLandingModuleInput: AnyObject {
    var openLink: ((URL) -> Void)? { get set }
    
    var landing: LandingData { get }
}

public enum PromoViewingResult {
    case close
}

public protocol DynamicPromoLandingModuleOutput: AnyObject {
    var onComplete: ((PromoViewingResult) -> Void)? { get set }
}

public class DynamicPromoLandingModule: BaseModule<DynamicPromoLandingModuleInput, DynamicPromoLandingModuleOutput> {}
