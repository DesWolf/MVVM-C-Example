//
//  QrPaymentPickerModuleAssembly.swift
//  Pods
//
//  Created by Vadim Kurochkin on 20/07/2020.
//  Copyright © 2020 MTS Bank. All rights reserved.
//

import Domain
import Swinject

public final class QrPaymentPickerModuleAssembly: Assembly {
    
    public func assemble(container: Container) {
        
        container.register(QrPaymentPickerModule.self) { (resolver, payments: [QrPaymentDataDecodedPayment]) in
            let viewModel = resolver.resolve(QrPaymentPickerViewModel.self, argument: payments)!
            let view = QrPaymentPickerViewController(viewModel: viewModel)
            let module = QrPaymentPickerModule(
                view: view,
                input: viewModel,
                output: viewModel
            )
            return module
        }
        
        container.register(QrPaymentPickerViewModel.self) { (resolver, payments: [QrPaymentDataDecodedPayment]) in
            let viewModel = QrPaymentPickerViewModel(payments: payments)
            return viewModel
        }
        
        container.register(QrPaymentPickerViewController.self) { (_, viewModel: QrPaymentPickerViewModel) in
            let viewController = QrPaymentPickerViewController(viewModel: viewModel)
            return viewController
        }
    }

    public init() {}
}
