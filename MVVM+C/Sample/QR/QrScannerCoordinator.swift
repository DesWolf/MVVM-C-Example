//
//  QrScannerCoordinator.swift
//  QrScanner
//
//  Created by Vadim Kurochkin on 21.07.2020.
//

import AVFoundation
import Coordinator
import Domain
import UIKit

final public class QrScannerCoordinator: AssemblyCoordinator<QrScannerResult> {
    
    public enum Transition {
        case present(presenter: UIViewController)
    }
    
    // MARK: - Private properties
     
    private let transition: Transition
    
    private let navigationController: UINavigationController = {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.modalPresentationStyle = .overFullScreen
        return navigationController
    }()
    
    // MARK: - Init

    public required init(transition: Transition) {
        self.transition = transition
        super.init()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(needDismissModalViews),
            name: Notification.Name("needDismissModalViews"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Life Cycle
    
    override public func assemblies() -> [Assembly] {
        [
            QrScannerDomainAssembly(),
            QrScannerModuleAssembly()
        ]
    }
    
    override public func start() {
        
        checkPermissions { [weak self] granted in
            if granted {
                self?.startScanner()
            } else {
                self?.onComplete?(.cancelled)
            }
        }
    }
    
    private func startScanner() {
        let module = self.resolver.resolve(QrScannerModule.self)!
        
        module.output.onComplete = { [weak self] result in
            guard let self = self else { return }
            self.dismiss(by: result)
        }
        
        switch self.transition {
        case .present(let presenter):
            navigationController.pushViewController(module.view, animated: false)
            presenter.present(navigationController, animated: true)
        }
    }
    
    private func checkPermissions(completion: @escaping (Bool) -> Void) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            let alertController = UIAlertController(
                title: nil,
                message: "Разрешить доступ вы можете в настройках телефона, в разделе «Конфиденциальность»",
                preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: "Настроить", style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
            })

            switch transition {
            case .present(let presenter):
                presenter.present(alertController, animated: true)
            }
        default:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
    
    private func dismiss(by result: QrScannerViewModel.ScanResult, animated: Bool = true) {
        switch self.transition {
        case .present(let presenter):
            switch result {
            case .payments(let payments): // вернули несколько платежей. выбираем и возвращаем выбранный
                let paymentPickerCoordinator = QrPaymentPickerCoordinator(
                    transition: .push(navigationController: self.navigationController),
                    payments: payments
                )
                paymentPickerCoordinator.onComplete = { [weak self] payment in
                    self?.navigationController.dismiss(animated: animated)
                    let decodedResult = QrScannerResult.DecodeResult(payment: payment)
                    self?.onComplete?(.decoded(decodedResult))
                }
                self.coordinate(to: paymentPickerCoordinator)
            case .payment(let payment): // вернулся один платеж. нечего выбирать, возвращаем его
                self.navigationController.dismiss(animated: animated)
                let decodedResult = QrScannerResult.DecodeResult(payment: payment)
                self.onComplete?(.decoded(decodedResult))
            case .dataFields(let dataFields): // платежей не нашлось. вернулись только декодированные из base64 поля
                self.navigationController.dismiss(animated: animated)
                self.onComplete?(.decoded(.notFound(dataFields)))
            case .manualInput: // возникла ошибка и пользователь нажал Ручной ввод
                self.navigationController.dismiss(animated: animated)
                self.onComplete?(.manualInput)
            case .cancelled: // пользователь нажал отмену
                self.navigationController.dismiss(animated: animated)
                self.onComplete?(.cancelled)
            }
        }
    }
    
    @objc private func needDismissModalViews() {
        self.dismiss(by: .cancelled, animated: false)
    }
}
