//
//  QrScannerViewController.swift
//  Pods
//
//  Created by Vadim Kurochkin on 20/07/2020.
//  Copyright © 2020 MTS Bank. All rights reserved.
//

import AVKit
import MTSBUI
import RxUtils
import UIKit

final class QrScannerViewController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - Initializable

    private let viewModel: QrScannerViewModel
    private let disposeBag = DisposeBag()
    // MARK: - Init

    init(viewModel: QrScannerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }
    
    // MARK: - Style
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Life cycle
    
    override func loadView() {
        let view = QrScannerView()
        view.viewModel = viewModel
        
        viewModel.showImagePicker
            .emit(to: showImagePicker())
            .disposed(by: disposeBag)
        
        viewModel.showFlashlight
            .emit(to: toggleFlashlight())
            .disposed(by: disposeBag)
        
        self.view = view
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        if device.isTorchActive, let _ = try? device.lockForConfiguration() {
            device.torchMode = .off
            device.unlockForConfiguration()
        }
    }
    
    // MARK: - Public methods
    
    func showImagePicker() -> Binder<Void> {
        return Binder(self) { this, _ in
            let controller = UIImagePickerController()
            controller.delegate = this
            controller.sourceType = .photoLibrary
            controller.allowsEditing = true
            
            this.present(controller, animated: true)
        }
    }
    
    func toggleFlashlight() -> Binder<Bool> {
        return Binder(self) { _, isFlashlightOn in
            guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
            if let _ = try? device.lockForConfiguration() {
                device.torchMode = isFlashlightOn ? .on : .off
                device.unlockForConfiguration()
            }
        }
    }
}

extension QrScannerViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return
        }
        
        picker.dismiss(animated: true, completion: nil)
        viewModel.scanQr(fromImage: image)
    }
}
