//
//  DynamicPromoLandingViewModel.swift
//  Pods
//
//  Created by Yaroslav Magin on 24/10/2020.
//  Copyright © 2020 MTS Bank. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

struct DynamicPromoLandingViewModelInput {
    let primaryButtonTap: ControlEvent<Void>
    let eulaButtonTap: ControlEvent<Void>
    let closeButtonTap: ControlEvent<Void>
    let openLink: Signal<URL>
}

struct BulletData {
    let iconUrl: String
    let text: String
    let subtext: String?
}

struct DynamicPromoLandingViewModelOutput {
    let promoTitle: String?
    let imageUrl: String?
    let infoTitle: String?
    let infoText: String?
    let primaryButtonTitle: String?
    let infoButtonTitle: String?
    let hintText: String?
    let bullets: [BulletData]?
}

protocol DynamicPromoLandingViewModelBindable {
    func bind(input: DynamicPromoLandingViewModelInput) -> DynamicPromoLandingViewModelOutput
}

final class DynamicPromoLandingViewModel: DynamicPromoLandingModuleInput & DynamicPromoLandingModuleOutput {
    let landing: LandingData
    
    var onComplete: ((PromoViewingResult) -> Void)?
    var openLink: ((URL) -> Void)?
    
    private let bag = DisposeBag()
    
    weak var viewInput: DynamicPromoLandingViewInput?
    
    init(landing: LandingData) {
        self.landing = landing
    }
}

// MARK: - DynamicPromoLandingViewOutput

extension DynamicPromoLandingViewModel: DynamicPromoLandingViewOutput {
    
}

// MARK: - DynamicPromoLandingViewModelBindable

extension DynamicPromoLandingViewModel : DynamicPromoLandingViewModelBindable {
    func bind(input: DynamicPromoLandingViewModelInput) -> DynamicPromoLandingViewModelOutput {
        
        input.primaryButtonTap.bind { [weak self] in
            if let link = self?.landing.buttonInfo?.link,
               let url = URL(string: link) {
                self?.openLink?(url)
            }
        }.disposed(by: bag)
        
        input.eulaButtonTap.bind { [weak self] in
            if let link = self?.landing.eulaInfo?.link,
               let url = URL(string: link) {
                self?.openLink?(url)
            }
        }.disposed(by: bag)
        
        input.closeButtonTap.bind { [weak self] in
            self?.onComplete?(.close)
        }.disposed(by: bag)
        
        input.openLink.emit(onNext:{ [weak self] url in
            self?.openLink?(url)
        }).disposed(by: bag)
        
        return DynamicPromoLandingViewModelOutput(
            promoTitle: landing.navBarTitle,
            imageUrl: landing.imageInfo?.image,
            infoTitle: landing.exampleInfo?.title,
            infoText: landing.exampleInfo?.text,
            primaryButtonTitle: landing.buttonInfo?.text,
            infoButtonTitle: landing.eulaInfo?.text,
            hintText: landing.hint,
            bullets: landing.points?.map { BulletData(iconUrl: $0.icon, text: $0.text, subtext: $0.subtext) }
        )
    }
}
