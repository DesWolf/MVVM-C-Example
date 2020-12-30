//
//  DynamicPromoLandingView.swift
//  DynamicPromoLanding
//
//  Created by Yaroslav Magin on 27.10.2020.
//  Copyright © 2020 MTS Bank. All rights reserved.
//

import MTSBUI
import RxCocoa
import SDWebImage
import UIKit

final class DynamicPromoLandingView: UIView {
    
    // MARK: - Nested types
    
    private enum Constants {
        static let backgroundColor: UIColor = .neutral800
        static let sideInset: CGFloat = 16
        static let stackContentInsets = UIEdgeInsets(top: 12, left: 0, bottom: 50, right: 0)
        
        enum EulaButton {
            static let titleColor: UIColor = .neutral100
            static let font: UIFont = .p2Medium
        }
        
        enum InfoBlock {
            static let titleFont: UIFont = .h3
            static let maxTitleLines = 2
            static let textFont: UIFont = .p2
            static let fontSize: CGFloat = 17
        }
        
        enum TitleImage {
            static let maxHeight: CGFloat = 194
        }
        
        enum Hint {
            static let font: UIFont = .p2
            static let textColor: UIColor = .neutral300
        }
        
        enum Spacing {
            static let afterTitleImage: CGFloat = 24
            static let afterTitleText: CGFloat = 8
            static let afterInfoText: CGFloat = 36
            static let betweenBullets: CGFloat = 12
            static let beforeHint: CGFloat = 16
            static let beforeButtons: CGFloat = 56
            static let afterEulaButton: CGFloat = 32
        }
    }
    
    // MARK: - Properties
    
    var viewModel: DynamicPromoLandingViewModelBindable? {
        didSet {
            let viewModelInput = DynamicPromoLandingViewModelInput(
                primaryButtonTap: primaryButton.rx.controlEvent(.touchUpInside),
                eulaButtonTap: eulaButton.rx.tap,
                closeButtonTap: navigationTitle.backButton.rx.tap,
                openLink: openLinkRelay.asSignal()
            )
            
            let output = viewModel!.bind(input: viewModelInput)
            
            setupView(withData: output)
        }
    }
    
    private let openLinkRelay = PublishRelay<URL>()
    
    private let primaryButton: StandardButton = {
        let button = StandardButton()
        button.apply(
            StandardButton.ComponentState(
                designedState: .default,
                style: .primary,
                arrowPosition: .none,
                badgeAppearance: .whenSetted
            )
        )
        return button
    }()
    
    private let eulaButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(Constants.EulaButton.titleColor, for: .normal)
        button.titleLabel?.font = Constants.EulaButton.font
        return button
    }()
    
    private let titleImage: UIImageView = UIImageView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.InfoBlock.titleFont
        label.numberOfLines = Constants.InfoBlock.maxTitleLines
        return label
    }()
    
    private let infoTextView: UITextView = LinkInteractableTextView()
    
    private let bulletsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.alignment = .fill
        return stack
    }()
    
    private let hintLabel: UILabel = {
        let label = UILabel()
        label.font = .p2
        label.textColor = .neutral300
        return label
    }()
    
    private let navigationTitle = NavigationTitle()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.distribution = .fill
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        stack.layoutMargins = Constants.stackContentInsets
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()
    
    // MARK: - Init
    
    init() {
        super.init(frame: .zero)
        
        backgroundColor = Constants.backgroundColor
        
        setConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private methods
    
    private func setupView(withData data: DynamicPromoLandingViewModelOutput) {
        if let title = data.promoTitle {
            navigationTitle.titleLabel.text = title
        }
        
        if let image = data.imageUrl, let url = URL(string: image) {
            titleImage.sd_setImage(with: url)
            contentStack.addArrangedSubview(titleImage)
            NSLayoutConstraint.activate([
                titleImage.heightAnchor.constraint(lessThanOrEqualToConstant: Constants.TitleImage.maxHeight)
            ])
            contentStack.setCustomSpacingUniversal(spacing: Constants.Spacing.afterTitleImage, after: titleImage)
        }
        
        if let infoTitle = data.infoTitle {
            titleLabel.text = infoTitle
            contentStack.addArrangedSubview(titleLabel)
            contentStack.setCustomSpacingUniversal(spacing: Constants.Spacing.afterTitleText, after: titleLabel)
        }
        
        if let infoText = data.infoText,
           // нельзя просто задавать font строке, поскольку внутри могут быть жирные и полужирные начертания
           // использование style позволяет сохранить внутреннее форматирование с применением шрифта
            let attributedString =
            """
            <span style=\"font-family: \(Constants.InfoBlock.textFont.familyName);
                            font-size: \(Constants.InfoBlock.fontSize)px\">
                \(infoText)
            </span>
            """.asHtmlAttributedString() {
            
            infoTextView.attributedText = attributedString
            
            contentStack.addArrangedSubview(infoTextView)
            infoTextView.delegate = self
            contentStack.setCustomSpacingUniversal(spacing: Constants.Spacing.afterInfoText, after: infoTextView)
        }
        
        if let bullets = data.bullets {
            for bullet in bullets {
                let bulletView = DynamicPromoLandingBullet()
                bulletView.configureWith(iconUrl: bullet.iconUrl, text: bullet.text, subtext: bullet.subtext)
                bulletView.textViewDelegate = self
                contentStack.addArrangedSubview(bulletView)
                contentStack.addCustomSpacingToEnd(spacing: Constants.Spacing.betweenBullets)
            }
        }
        
        if let hint = data.hintText {
            contentStack.addCustomSpacingToEnd(spacing: Constants.Spacing.beforeHint)
            hintLabel.text = hint
            contentStack.addArrangedSubview(hintLabel)
        }
        
        if data.primaryButtonTitle != nil || data.infoButtonTitle != nil {
            contentStack.addCustomSpacingToEnd(spacing: Constants.Spacing.beforeButtons)
        }
        
        if let infoButtonTitle = data.infoButtonTitle {
            eulaButton.setTitle(infoButtonTitle, for: .normal)
            contentStack.addArrangedSubview(eulaButton)
            contentStack.setCustomSpacingUniversal(spacing: Constants.Spacing.afterEulaButton, after: eulaButton)
        }
        
        if let primaryButtonTitle = data.primaryButtonTitle {
            primaryButton.title = .text(primaryButtonTitle)
            contentStack.addArrangedSubview(primaryButton)
        }
        
        NSLayoutConstraint.activate(
            contentStack.arrangedSubviews.map { $0.widthAnchor.constraint(equalTo: contentStack.widthAnchor) }
        )
    }
    
    private func setConstraints() {
        let scroll = UIScrollView()
        addSubviewWithAutolayout(scroll)
        
        scroll.addSubviewWithAutolayout(contentStack)
        addSubviewWithAutolayout(navigationTitle)
        NSLayoutConstraint.activate([
            
            navigationTitle.topAnchor.constraint(equalTo: saferAreaLayoutGuide.topAnchor),
            navigationTitle.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationTitle.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            scroll.topAnchor.constraint(equalTo: navigationTitle.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scroll.topAnchor),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: scroll.bottomAnchor),
            contentStack.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            contentStack.widthAnchor.constraint(equalTo: widthAnchor, constant: -2 * Constants.sideInset)
        ])
    }
}

// MARK: - UITextViewDelegate implementation

extension DynamicPromoLandingView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        openLinkRelay.accept(URL)
        return false
    }
}
