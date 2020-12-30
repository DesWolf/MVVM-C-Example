//
//  QrScannerView.swift
//  QrScanner
//
//  Created by Vadim Kurochkin on 20.07.2020.
//

import MTSBUI
import RxCocoa
import RxSwift
import UIKit

enum QrScannerState {
    case initial
    case loading
    case success
    case fail
}

final class QrScannerView: UIView {
    
    enum Style {
        static let holeHorizInset: CGFloat = 45
        static let holeCornerRadius: CGFloat = 12
    }
    
    private enum Constants {
        enum PickImageButton {
            static let insets = UIEdgeInsets(top: 0, left: 0, bottom: -50, right: 0)
        }
        
        enum FlashlightButton {
            static let size = CGSize(width: 56, height: 56)
            static let insets = UIEdgeInsets(top: 0, left: 0, bottom: -24, right: 0)
        }
    }
    
    var holeSideSize: CGFloat {
        UIScreen.main.bounds.width - 2 * Style.holeHorizInset
    }
    
    var viewModel: QrScannerViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            
            let input = QrScannerViewModelInput(
                captureResult: captureView.capturedValue.asObservable(),
                resetTapped: fileView.errorView.backButton.rx.tap,
                backTapped: backButton.rx.tap,
                errorCloseTapped: errorView.closeButton.rx.tap,
                manualInputTapped: ControlEvent<Void>(events:
                    Observable.of(
                        errorView.manualInputButton.rx.tap,
                        fileView.errorView.manualInputButton.rx.controlEvent(.touchUpInside)
                    ).merge()),
                pickImageTapped: ControlEvent<Void>(events:
                    Observable.of(
                        pickImageButton.rx.tap,
                        fileView.errorView.loadAnotherPhotoButton.rx.tap
                    ).merge()),
                flashlightTapped: flashlightButton.rx.tap
            )
            
            let output = viewModel.bind(input: input)
            
            output.state.drive(onNext: { [weak self] state in
                guard let self = self else { return }
                
                if self.isCameraActive {
                    self.holeView.state = state
                    self.errorView.isHidden = (state != .fail)
                } else {
                    self.fileView.state = state
                }
                
                if case .initial = state {
                    self.reset()
                }
            }).disposed(by: disposeBag)
            
            output.userImageState.drive(onNext: { [weak self] image in
                self?.switchToFileMode(scanningImage: image)
            })
            
            output.infoText.drive(onNext: { [weak self] text in
                self?.infoLabel.text = text
            }).disposed(by: disposeBag)
            
            output.flashlightTurnOn.drive(onNext: { [weak self] shouldTurnFlashlightOn in
                self?.flashlightButton.isSelected = shouldTurnFlashlightOn
            })
        }
    }
    
    private var isCameraActive = true
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Views
    
    private let captureView = VideoCapturePreviewSmartIdView(documentTypes: "barcode")
    private let holeView = QrScannerHoleView(cornerRadius: Style.holeCornerRadius)
    private let errorView = QrScannerErrorView()
    private lazy var overlayView = QrScannerOverlayView(
        holeSideSize: holeSideSize,
        holeCornerRadius: Style.holeCornerRadius
    )
    
    private let pickImageButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setTitle("Сканировать код из фото", for: .normal)
        button.setTitleColor(.neutral800, for: .normal)
        button.titleLabel?.font = .p2
        return button
    }()
    
    private let backButton: ExtendableAreaButton = {
        let button = ExtendableAreaButton()
        button.extendingInsets = 15
        button.setImage(UIImage.inCurrentBundle(imageName: "back_white"), for: .normal)
        button.adjustsImageWhenHighlighted = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let flashlightButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .neutral800
        button.layer.cornerRadius = 26
        button.adjustsImageWhenHighlighted = false
        button.setImage(UIImage.inCurrentBundle(imageName: "flash_light_on"), for: .normal)
        button.setImage(UIImage.inCurrentBundle(imageName: "flash_light_off"), for: .selected)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = .medium(size: 18)
        label.text = "Оплата по QR"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
    }()
    
    private let infoLabel = QrScannerAnimatedLabel(text: "Наведите камеру\nна QR-код")
    
    private let fileView = QrScannerFileView()
    
    private let navBarGuide = UILayoutGuide()
    private let infoGuide = UILayoutGuide()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupVideoCaptureView()
        setupOverlayView()
        setupNavBar()
        setupInfoText()
        setupPickImageButton()
        setupFlashlightButton()
        setupErrorView()
        setupFileScannerView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Life cycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        captureView.roiFrame = frame
    }
    
    // MARK: - Private methods
    private func switchToFileMode(scanningImage: UIImage) {
        fileView.isHidden = false
        fileView.setScanningImage(scanningImage)
        
        isCameraActive = false
        captureView.isHidden = true
        holeView.isHidden = true
        overlayView.isHidden = true
    }
    
    private func reset() {
        fileView.isHidden = true
        
        isCameraActive = true
        captureView.isHidden = false
        holeView.isHidden = false
        overlayView.isHidden = false
        
        captureView.startCapturing()
    }
    
    // MARK: - Layout Constrains
    
    private func setupVideoCaptureView() {

        addSubview(captureView)
        NSLayoutConstraint.activate([
            captureView.widthAnchor.constraint(equalTo: widthAnchor),
            captureView.heightAnchor.constraint(equalTo: heightAnchor),
            captureView.centerXAnchor.constraint(equalTo: centerXAnchor),
            captureView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func setupOverlayView() {
        
        addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.widthAnchor.constraint(equalTo: widthAnchor),
            overlayView.heightAnchor.constraint(equalTo: heightAnchor),
            overlayView.centerXAnchor.constraint(equalTo: centerXAnchor),
            overlayView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addSubview(holeView)
        NSLayoutConstraint.activate([
            holeView.widthAnchor.constraint(equalToConstant: holeSideSize),
            holeView.heightAnchor.constraint(equalToConstant: holeSideSize),
            holeView.centerXAnchor.constraint(equalTo: centerXAnchor),
            holeView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func setupNavBar() {
        
        addLayoutGuide(navBarGuide)
        NSLayoutConstraint.activate([
            navBarGuide.leftAnchor.constraint(equalTo: leftAnchor),
            navBarGuide.rightAnchor.constraint(equalTo: rightAnchor),
            navBarGuide.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        if #available(iOS 11.0, *) {
            navBarGuide.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            navBarGuide.topAnchor.constraint(equalTo: topAnchor).isActive = true
        }

        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: navBarGuide.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navBarGuide.centerYAnchor)
        ])
        
        addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 24),
            backButton.leftAnchor.constraint(equalTo: navBarGuide.leftAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: navBarGuide.centerYAnchor)
        ])
    }
    
    private func setupInfoText() {
        
        addLayoutGuide(infoGuide)
        NSLayoutConstraint.activate([
            infoGuide.leftAnchor.constraint(equalTo: leftAnchor),
            infoGuide.rightAnchor.constraint(equalTo: rightAnchor),
            infoGuide.topAnchor.constraint(equalTo: navBarGuide.bottomAnchor),
            infoGuide.bottomAnchor.constraint(equalTo: holeView.topAnchor)
        ])
        
        addSubview(infoLabel)
        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: infoGuide.centerXAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: infoGuide.centerYAnchor)
        ])
    }
    
    private func setupFlashlightButton() {
        addSubviewWithAutolayout(flashlightButton)
        NSLayoutConstraint.activate([
            flashlightButton.widthAnchor.constraint(equalToConstant: Constants.FlashlightButton.size.width),
            flashlightButton.heightAnchor.constraint(equalToConstant: Constants.FlashlightButton.size.height),
            flashlightButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            flashlightButton.bottomAnchor.constraint(equalTo: pickImageButton.topAnchor,
                                                     constant: Constants.FlashlightButton.insets.bottom)
        ])
    }
    
    private func setupErrorView() {
        
        addSubview(errorView)
        NSLayoutConstraint.activate([
            errorView.rightAnchor.constraint(equalTo: rightAnchor),
            errorView.leftAnchor.constraint(equalTo: leftAnchor),
            errorView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupPickImageButton() {
        addSubviewWithAutolayout(pickImageButton)
        NSLayoutConstraint.activate([
            pickImageButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            pickImageButton.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: Constants.PickImageButton.insets.bottom
            )
        ])
    }
    
    private func setupFileScannerView() {
        addSubviewWithAutolayout(fileView)
        fileView.isHidden = true
        NSLayoutConstraint.activate([
            fileView.topAnchor.constraint(equalTo: topAnchor),
            fileView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fileView.trailingAnchor.constraint(equalTo: trailingAnchor),
            fileView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
