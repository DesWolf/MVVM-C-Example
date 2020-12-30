//
//  DynamicPromoLandingViewController.swift
//  Pods
//
//  Created by Yaroslav Magin on 24/10/2020.
//  Copyright © 2020 MTS Bank. All rights reserved.
//

import UIKit

protocol DynamicPromoLandingViewInput: AnyObject {}

protocol DynamicPromoLandingViewOutput: AnyObject {}

final class DynamicPromoLandingViewController: UIViewController {

    // MARK: - Initializable

    private let output: DynamicPromoLandingViewOutput

    // MARK: - Initializers

    init(output: DynamicPromoLandingViewOutput) {
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    override func loadView() {
        super.loadView()
        
        let view = DynamicPromoLandingView()

        if let viewModel = output as? DynamicPromoLandingViewModelBindable {
            view.viewModel = viewModel
        }
        
        self.view = view
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.tabBarController?.tabBar.isHidden = false
    }
}

// MARK: - DynamicPromoLandingViewInput

extension DynamicPromoLandingViewController: DynamicPromoLandingViewInput {}
