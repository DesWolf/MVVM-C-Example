//
//  TabBarTabBarCoordinator.swift
//  MtsMoney
//
//  Created by Alexei Pozdnyakov on 10/09/2019.
//  Copyright © 2019 MTS Bank. All rights reserved.
//

import Coordinator
import DynamicPromoLanding
import Foundation

@objc class TabBarCoordinator: BaseCoordinator {
    var tabBarFactory: ModuleFactory<TabBarViewController>!
    @objc var moneyCoordinator: MoneyCoordinator!
    @objc var paymentCoordinator: PaymentCoordinator!
    var historyCoordinator: HistoryCoordinator!
    var chatCoordinator: OnlineChatCoordinator!
    var moreCoordinator: MoreCoordinator!
    
    var deepLinkAction: DeeplinkAction?
    
    private let rootCoordinator: AppCoordinator = AppCoordinator.shared

    weak var tabBarController: TabBarViewController?

    @objc func showTabBar() -> TabBarViewController? {
        Design().apply()
        tabBarController = tabBarFactory.handler()
        addMoneyFlow()
        addPaymentFlow()
        addHistoryFlow()
        if #available(iOS 11.0, *) {
            addChatFlow()
        }
        addMoreFlow()
        return tabBarController
    }

    @objc func checkDeeplink() {
        guard let deepLink = deepLinkAction else {
            return
        }

        deepLinkAction = nil
        
        guard let navController = tabBarController?.selectedViewController as? UINavigationController,
              let selectedViewController = navController.viewControllers.first else {
            return
        }
        
        switch deepLink {
        case let .deeplink(url):
            switch url.type {
            case .main:
                openMainScreen()
            case .templates, .autopayments:
                openPaymentScreen()
            case .history:
                openHistoryScreen()
            case .profile:
                openMoreScreen()
            case .catalog(let category):
                openPaymentCategoryScreen(categoryName: category)
            case .ncpkFull:
                openFullNcpk()
            case .unknownOrOldNavigationDeeplink,
                 .tutorial:
                let openDebitAction: (() -> Void)?
                if let navigationController = selectedViewController.navigationController {
                    openDebitAction = moneyCoordinator.weekendDebitOpenBlock(
                        navigationController: navigationController
                    )
                } else {
                    openDebitAction = nil
                }

                ObjcRouting.pushOldNavigationViewModel(
                    with: url,
                    from: selectedViewController,
                    openDebitAction: openDebitAction
                )
            case .personalOffer(let id):
                openPersonalProposeScreen(withOfferId: id)
            case .openDeposit(let prodCode):
                openDeposit(with: prodCode)
            case .faRequest(let offerId):
                openShortLoanForm(offerId: offerId)
            case .landing(let id):
                if ServiceLocator.shared.toggleService.isEnabled(DynamicPromoLandingToggles.isEnabled) {
                    openLanding(withId: id)
                } else {
                    openMainScreen()
                }
            case .legacy:
                ObjcRouting.pushNavigationViewController(with: url, from: selectedViewController)
            }

        case let .forceTouch(type):
            switch type {
            case ForceTouchTypeFillPhone, ForceTouchTypeTransfer:
                ObjcRouting.pushNavigationViewController(withForceTouchType: type, from: selectedViewController)
            case ForceTouchTypeHistory:
                openHistoryScreen()
            case ForceTouchTypeTemplates:
                openPaymentScreen()
            case ForceTouchTypePushNotificationDetail:
                openPushDetailScreen()
            default:
                break
            }
        }
    }

    private func addMoneyFlow() {
        NotificationCenter.default.removeObserver(
            self,
            name: .openMainScreen,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: .openMainScreenWithAnimation,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: .openSupportEmailScreen,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openMainScreen),
            name: .openMainScreen,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openMainScreenWithAnimation),
            name: .openMainScreenWithAnimation,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSupportEmailScreen),
            name: .openSupportEmailScreen,
            object: nil
        )

        let nc = moneyCoordinator.startFromTabBar()
        moneyCoordinator.openPaymentScreen = { [weak self] in
            self?.openPaymentScreenOnly()
        }
        tabBarController?.addChild(nc)
    }

    private func addPaymentFlow() {
        NotificationCenter.default.removeObserver(self, name: .openPaymentScreen, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openPaymentScreen),
            name: .openPaymentScreen,
            object: nil
        )
        NotificationCenter.default.removeObserver(self, name: .openPaymentScreenOnly, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openPaymentScreenOnly),
            name: .openPaymentScreenOnly,
            object: nil
        )
        let nc = paymentCoordinator.startFromTabBar()
        tabBarController?.addChild(nc)
    }

    private func addHistoryFlow() {
        NotificationCenter.default.removeObserver(self, name: .openHistoryScreen, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openHistoryScreen),
            name: .openHistoryScreen,
            object: nil
        )
        historyCoordinator.openCreatePayment = { [weak self] in
            self?.tabBarController?.selectedIndex = 1
        }
        let nc = historyCoordinator.startFromTabBar()
        tabBarController?.addChild(nc)
    }
    
    private func addChatFlow() {
        NotificationCenter.default.removeObserver(self, name: .openChatScreen, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openChatScreen),
            name: .openChatScreen,
            object: nil
        )
        let appVersion = CacheManager.sharedInstance()?.appVersion ?? "undefined"
        if let rboId = MtsBankService.sharedInstance().bankId {
            let input = OnlineChatCoordinator.Input(appVersion: appVersion, rboId: rboId)
            chatCoordinator.configureWithInput(input)
            chatCoordinator.startFromTabBar(tabBarController)
        }
    }

    private func addMoreFlow() {
        let nc = moreCoordinator.startFromTabBar()
        moreCoordinator.openPaymentScreen = { [weak self] in
            self?.openPaymentScreenOnly()
        }
        moreCoordinator.openMoneyScreen = { [weak self] in
            self?.openMainScreen()
        }
        tabBarController?.addChild(nc)
    }

    @objc func openMainScreen() {
        tabBarConrollersPopToRoot(animated: false)
        tabBarController?.selectedIndex = 0
    }
    
    @objc func openMainScreenWithAnimation() {
        tabBarConrollersPopToRoot(animated: true)
        tabBarController?.selectedIndex = 0
    }

    @objc func openPaymentScreenOnly() {
        tabBarConrollersPopToRoot(animated: false)
        tabBarController?.selectedIndex = 1
    }

    @objc func openPaymentScreen() {
        tabBarController?.selectedIndex = 1
        if
            let navController = tabBarController?.viewControllers?[1] as? UINavigationController,
            let viewController = navController.viewControllers.last
        {
            paymentCoordinator.showPaymentTemplates(from: viewController)
        }
    }
    
    @objc private func openPushDetailScreen() {
        guard
            let navController = tabBarController?.selectedViewController as? UINavigationController,
            let userInfo = RemoteNotifications.sharedInstance()?.userInfo,
            let date = userInfo["receivedData"] as? Date,
            let text = userInfo["pushText"] as? String,
            let title = userInfo["pushTitle"] as? String,
            let requestId = userInfo["requestId"] as? String
        else { return }
        let childCoordinator = PushNotificationsHistoryDetailCoordinator(
            input: .init(
                title: title,
                date: date,
                text: text,
                requestId: requestId,
                source: .push
            ),
            sourceNavigation: navController
        )
        rootCoordinator.coordinate(to: childCoordinator)
    }
    
    @objc func openPaymentCategoryScreen(categoryName: String) {
        tabBarController?.selectedIndex = 1
        if let navController = tabBarController?.viewControllers?[1] as? UINavigationController,
           let viewController = navController.viewControllers.last as? PaymentViewController,
           let category = CatalogService.shared().category(withName: categoryName) {
            paymentCoordinator.showPaymentCategory(
                from: viewController,
                category: category
            )
        }
    }

    func openFullNcpk() {
        
        guard let navController = tabBarController?.viewControllers?[0] as? UINavigationController,
            let vc = navController.viewControllers.last else { return }
        
        let bankId = MtsBankService.sharedInstance().bankId
        
        if let bankId = bankId, let rboId = Int(bankId) {
            let input = CreditCreationCoordinator.Input(
                rboId: rboId
            )
            
            let creditCreationCoordinator = CreditCreationCoordinator(
                transition: .push(source: vc),
                input: input
            )
            self.rootCoordinator.coordinate(to: creditCreationCoordinator)
        } else {
            let viewModel = ApplyProductsViewModel()
            viewModel?.currentTabIndex = 1
            ObjcRouting.pushNavigationViewController(withRootObjectViewModel: viewModel, from: vc)
        }
    }
    
    @objc func openHistoryScreen() {
        tabBarConrollersPopToRoot(animated: false)
        tabBarController?.selectedIndex = 2
    }

    @objc func openChatScreen() {
        tabBarConrollersPopToRoot(animated: false)
        tabBarController?.selectedIndex = 3
    }
    
    @objc func openSupportEmailScreen() {
        guard
            let navController = tabBarController?.selectedViewController as? UINavigationController,
            let vc = navController.viewControllers.last
        else {
            return
        }
        ObjcRouting.pushViewController(withViewModel: SupportMailViewModel.self, from: vc)
    }
    
    @objc func openMoreScreen() {
        tabBarConrollersPopToRoot(animated: false)
        tabBarController?.selectedIndex = 4
    }

    @objc func openDeeplink(url: URL) {
        self.deepLinkAction = .deeplink(url)
        self.checkDeeplink()
    }
    
    private func openPersonalProposeScreen(withOfferId offerId: String) {

        guard let navigation = tabBarController?.selectedViewController as? UINavigationController else {
            assertionFailure()
            
            return
        }
        
        let personalProposesCoordinator = PersonalProposeCoordinator(
            offerId: offerId,
            rootNavigation: navigation
        )
        
        rootCoordinator.coordinate(to: personalProposesCoordinator)
    }

    private func openDeposit(with prodCode: String?) {
        guard let navigation = tabBarController?.selectedViewController else {
    
            assertionFailure()
            
            return
        }
        let depositCalculatorCoordinator = DepositCalculatorCoordinator(
            viewController: navigation,
            deepLinkProdCode: prodCode
        )
        
        rootCoordinator.coordinate(to: depositCalculatorCoordinator)
    }
    
    private func openShortLoanForm(offerId: String) {
        let rootNavigtion = tabBarController?.selectedViewController as? UINavigationController
        
        guard
            let topController = rootNavigtion?.topViewController,
            let rboId = Int(MtsBankService.sharedInstance().bankId)
            else {
                assertionFailure()
                
                return
        }
        
        let inputData = ShortCreditCreationCoordinator.Input(
            rboId: rboId,
            offerId: offerId
        )
        
        let shortCoordinator = ShortCreditCreationCoordinator(
            transition: .presentInNav(source: topController),
            input: inputData
        )
        
        shortCoordinator.onComplete = { [weak topController] _ in
            topController?.navigationController?.tabBarController?.tabBar.isHidden = false
        }
        
        rootCoordinator.coordinate(to: shortCoordinator)
    }

    private func openLanding(withId landingId: String) {
        guard let navigation = tabBarController?.selectedViewController as? UINavigationController else {
            return
        }
        
        if let landing = LandingService.sharedInstance().landings?.first(where: { $0.landingId == landingId })  {
            let landingCoordinator = DynamicPromoLandingCoordinator(
                landing: landing,
                navigationController: navigation
            )
            
            landingCoordinator.openLink = DeeplinkRouter.openURL
            
            landingCoordinator.onComplete = { [weak navigation] result in
                switch result {
                case .close:
                    navigation?.popViewController(animated: true)
                }
            }
            
            rootCoordinator.coordinate(to: landingCoordinator)
        }
    }
    
    func tabBarConrollersPopToRoot(animated: Bool) {
        tabBarController?.viewControllers?.forEach {
            if let navigationController = $0 as? UINavigationController {
                navigationController.popToRootViewController(animated: animated)
            }
        }
    }
}

extension TabBarCoordinator {
    private enum Constants {
        static let numberOfTabs = 5
        static let chatTabIndex = 3
    }
}
