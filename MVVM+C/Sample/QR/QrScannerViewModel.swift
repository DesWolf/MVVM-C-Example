//
//  QrScannerViewModel.swift
//  Pods
//
//  Created by Vadim Kurochkin on 20/07/2020.
//  Copyright © 2020 MTS Bank. All rights reserved.
//

import Domain
import Foundation
import RxUtils
import SESmartID
import Swinject

struct QrScannerViewModelInput {
    let captureResult: Observable<String>
    let resetTapped: ControlEvent<Void>
    let backTapped: ControlEvent<Void>
    let errorCloseTapped: ControlEvent<Void>
    let manualInputTapped: ControlEvent<Void>
    let pickImageTapped: ControlEvent<Void>
    let flashlightTapped: ControlEvent<Void>
}

struct QrScannerViewModelOutput {
    let state: Driver<QrScannerState>
    let userImageState: Driver<UIImage>
    let infoText: Driver<String>
    let flashlightTurnOn: Driver<Bool>
}

protocol QrScannerViewModelBindable {
    func bind(input: QrScannerViewModelInput) -> QrScannerViewModelOutput
}

final public class QrScannerViewModel: NSObject,
        QrScannerModuleInput & QrScannerModuleOutput {
    
    private enum Consts {
        enum StateText {
            static let loading = "Наведите камеру\nна QR-код"
            static let processing = "Обрабатываем код..."
            static let complete = "Готово"
        }
        
        static let scanTimeoutSec: TimeInterval = 60
        static let delayBeforeDismissMs = 1000
        
        static let flashlightInitiallyOn = false
    }
    
    public enum ScanResult {
        case payments([QrPaymentDataDecodedPayment])
        case payment(QrPaymentDataDecodedPayment)
        case dataFields([String:String])
        case manualInput
        case cancelled
    }
    
    var resolver: Resolver!
    public var onComplete: ((ScanResult) -> Void)?
    
    private let state = BehaviorRelay<QrScannerState>(value: .initial)
    private let infoText = BehaviorRelay<String>(value: Consts.StateText.loading)
    private let isFlashlightOn = BehaviorRelay<Bool>(value: Consts.flashlightInitiallyOn)
    
    private let imagePickerRelay = PublishRelay<Void>()
    var showImagePicker: Signal<Void> {
        return self.imagePickerRelay.asSignal()
    }
    
    private let imageRelay = PublishRelay<UIImage>()
    
    var showFlashlight: Signal<Bool> {
        return self.isFlashlightOn.asSignal(onErrorJustReturn: Consts.flashlightInitiallyOn)
    }
    
    private let disposeBag = DisposeBag()
    private let fileScanner: QrFileScannerProtocol
    private var dataDecoder: QrPaymentDataDecoderModel!
    
    private var timeoutTimer: Timer?
    
    // MARK: - Init
    init(fileScanner: QrFileScannerProtocol) {
        self.fileScanner = fileScanner
        super.init()
        startTimer()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    // MARK: - Public methods
    
    func scanQr(fromImage image: UIImage) {
        startTimer()
        imageRelay.accept(image)
        fileScanner.processFileImage(image: image)
    }
    
    // MARK: - Private methods
    
    private func decodeData(_ base64String: String) {
        stopTimer()
        state.accept(.loading)
        infoText.accept(Consts.StateText.processing)
        dataDecoder = resolver.resolve(QrPaymentDataDecoderModel.self, argument: base64String)!
        dataDecoder.decodeData { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let result):
                self.state.accept(.success)
                self.infoText.accept(Consts.StateText.complete)
                self.handleResult(result)
            case .failure:
                self.state.accept(.fail)
                self.infoText.accept(Consts.StateText.loading)
            }
        }
    }
    
    private func handleResult(_ result: QrPaymentDataDecoderModel.DecodeResult) {
        let deadline: DispatchTime = .now() + .milliseconds(Consts.delayBeforeDismissMs)
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            switch result {
            case .dataFields(let dataFields):
                self?.onComplete?(.dataFields(dataFields))
            case .payments(let payments) where payments.count == 1 :
                guard let payment = payments.first else { return }
                self?.onComplete?(.payment(payment))
            case .payments(let payments):
                self?.onComplete?(.payments(payments))
            }
        }
    }
    
    private func reset() {
        startTimer()
        state.accept(.initial)
        infoText.accept(Consts.StateText.loading)
    }
    
    // MARK: - Timeout
    
    private func startTimer() {
        stopTimer()
        timeoutTimer = Timer.scheduledTimer(
            timeInterval: Consts.scanTimeoutSec,
            target: self,
            selector: #selector(scanTimeout),
            userInfo: nil,
            repeats: false
        )
    }
    
    private func stopTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    @objc func scanTimeout() {
        self.state.accept(.fail)
        self.infoText.accept(Consts.StateText.loading)
    }
    
    // MARK: - App State
    
    @objc func didBecomeActive() {
        self.isFlashlightOn.accept(isFlashlightOn.value)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension QrScannerViewModel: QrScannerViewModelBindable {
    
    func bind(input: QrScannerViewModelInput) -> QrScannerViewModelOutput {
        
        input.captureResult.bind { [weak self] base64String in
            self?.decodeData(base64String)
        }.disposed(by: disposeBag)

        input.backTapped.bind { [weak self] _ in
            self?.onComplete?(.cancelled)
        }.disposed(by: disposeBag)
        
        input.resetTapped.bind { [weak self] _ in
            self?.reset()
        }.disposed(by: disposeBag)

        input.errorCloseTapped.bind { [weak self] _ in
            self?.onComplete?(.cancelled)
        }.disposed(by: disposeBag)

        input.manualInputTapped.bind { [weak self] _ in
            self?.onComplete?(.manualInput)
        }.disposed(by: disposeBag)
        
        input.pickImageTapped.bind { [weak self] _ in
            self?.stopTimer()
            self?.imagePickerRelay.accept(())
        }.disposed(by: disposeBag)
        
        input.flashlightTapped.bind { [weak self] _ in
            guard let currentFlashlightState = self?.isFlashlightOn.value else {
                return
            }
            self?.isFlashlightOn.accept(!currentFlashlightState)
        }
        
        fileScanner.result.subscribe { [weak self] result in
            guard let self = self, let res = result.element else { return }
            switch res {
            case .success(let value):
                self.decodeData(value)
            case .failure:
                self.state.accept(.fail)
            }
        }.disposed(by: disposeBag)
        
        return QrScannerViewModelOutput(
            state: state.asDriver(),
            userImageState: imageRelay.asDriver(onErrorJustReturn: UIImage()),
            infoText: infoText.asDriver(),
            flashlightTurnOn: isFlashlightOn.asDriver()
        )
    }
}
