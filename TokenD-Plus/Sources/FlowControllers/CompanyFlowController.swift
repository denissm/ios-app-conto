import UIKit
import TokenDWallet
import SideMenuController

class CompanyFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private(set) var isAuthorized: Bool = true
    
    private let sideNavigationController: SideMenuController
    
    private let sideMenuViewController = SideMenu.ViewController()
    
    private let company: CompaniesList.Model.Company
    
    private var localAuthFlow: LocalAuthFlowController?
    private var timeoutSubscribeToken: TimerUIApplication.SubscribeToken = TimerUIApplication.SubscribeTokenInvalid
    private var backgroundTimer: Timer?
    private var backgroundToken: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    
    // MARK: - Callbacks
    
    private let onSignOut: () -> Void
    private let onEnvironmentChanged: () -> Void
    private let onLocalAuthRecoverySucceeded: () -> Void
    
    // MARK: -
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        company: CompaniesList.Model.Company,
        onSignOut: @escaping () -> Void,
        onEnvironmentChanged: @escaping () -> Void,
        onLocalAuthRecoverySucceeded: @escaping () -> Void
        ) {
        
        self.company = company
        self.onSignOut = onSignOut
        self.onEnvironmentChanged = onEnvironmentChanged
        self.onLocalAuthRecoverySucceeded = onLocalAuthRecoverySucceeded
        
        SideMenuController.preferences.drawing.menuButtonImage = Assets.menuIcon.image
        SideMenuController.preferences.drawing.menuButtonWidth = 35
        SideMenuController.preferences.drawing.centerPanelShadow = true
        SideMenuController.preferences.animating.statusBarBehaviour = .horizontalPan
        SideMenuController.preferences.animating.transitionAnimator = nil
        
        self.sideNavigationController = SideMenuController()
        
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: rootNavigation
        )
        
        self.timeoutSubscribeToken = TimerUIApplication.subscribeForTimeoutNotification(handler: { [weak self] in
            self?.isAuthorized = false
            self?.stopUserActivityTimer()
            _ = self?.checkIsAuthorized()
        })
    }
    
    deinit {
        TimerUIApplication.unsubscribeFromTimeoutNotification(self.timeoutSubscribeToken)
        self.timeoutSubscribeToken = TimerUIApplication.SubscribeTokenInvalid
    }
    
    // MARK: - Public
    
    public func run() {
        self.setupSideMenu()
        self.showHomeScreen()
        self.startUserActivityTimer()
    }
    
    // MARK: - Private
    
    private func showHomeScreen() {
        self.rootNavigation.setRootContent(
            self.sideNavigationController,
            transition: .fade,
            animated: true
        )
    }
    
    // MARK: - Setup
    
    private func setupSideMenu() {
        let headerModel = SideMenu.Model.HeaderModel(
            icon: Assets.logo.image,
            title: self.userDataProvider.userEmail,
            subTitle: self.company.name
        )
        let sections: [[SideMenu.Model.MenuItem]] = []
        
        SideMenu.Configurator.configure(
            viewController: self.sideMenuViewController,
            header: headerModel,
            sections: sections,
            routing: SideMenu.Routing(
                showBalances: { [weak self] in
                    self?.runBalancesFlow()
                },
                showSettings: { [weak self] in
                    self?.runSettingsFlow()
                },
                showCompanies: { [weak self] in
                    self?.runCompanyListFlow()
                },
                showReceive: { [weak self] in
                    self?.showReceiveScene()
                },
                showContribute: { [weak self] in
                    self?.showContribute()
                },
                showMovements: { [weak self] in
                    self?.showMovementsScene()
                })
        )
        
        self.sideNavigationController.embed(sideViewController: self.sideMenuViewController)
        self.runReposPreload()
        self.runBalancesFlow()
    }
    
    // MARK: - Side Menu Navigation
    
    private func runReposPreload() {
        _ = self.reposController.assetsRepo.observeAssets()
        _ = self.reposController.balancesRepo.observeBalancesDetails()
    }
    
    private func runBalancesFlow() {
        let balancesFlow = BalancesListFlowController(
            company: self.company,
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation
        )
        self.currentFlowController = balancesFlow
        balancesFlow.run(
            showRootScreen: { [weak self] (vc) in
                self?.sideNavigationController.embed(centerViewController: vc)
        })
    }
    
    private func runSettingsFlow() {
        let flow = SettingsFlowController(
            onSignOut: self.onSignOut,
            onEnvironmentChanged: self.onEnvironmentChanged,
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation
        )
        self.currentFlowController = flow
        flow.run(showRootScreen: { [weak self] (vc) in
            self?.sideNavigationController.embed(centerViewController: vc)
        })
    }
    
    private func runSaleFlow() {
        let flow = SalesFlowController(
            ownerAccountId: self.company.accountId,
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation
        )
        self.currentFlowController = flow
        flow.run(
            showRootScreen: { [weak self] (vc) in
                self?.sideNavigationController.embed(centerViewController: vc)
            },
            onShowMovements: {}
        )
    }
    
    private func runPollsFlow() {
        let flow = PollsFlowController(
            ownerAccountId: self.company.accountId,
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation
        )
        self.currentFlowController = flow
        flow.run(showRootScreen: { [weak self] (vc) in
            self?.sideNavigationController.embed(centerViewController: vc)
        })
    }
    
    private func runCompanyListFlow() {
        let addAccountWorker = AddCompany.AddCompanyWorker(
            integrationsApi: self.flowControllerStack.apiV3.integrationsApi,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        let flowController = CompaniesListFlowController(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation,
            addAccountWorker: addAccountWorker,
            onSignOut: { [weak self] in
                self?.onSignOut()
            },
            onEnvironmentChanged: { [weak self] in
                self?.performSignOut()
            },
            onLocalAuthRecoverySucceeded: { [weak self] in
                self?.onLocalAuthRecoverySucceeded()
        })
        self.currentFlowController = flowController
        flowController.run(showRootScreen: { [weak self] (vc) in
            self?.sideNavigationController.embed(centerViewController: vc)
        })
    }
    
    private func showMovementsScene() {
        let vc = self.setupMovementsScene()
        
        self.sideNavigationController.embed(centerViewController: vc)
    }
    
    private func setupMovementsScene() -> UIViewController {
        let navigationController = NavigationController()
        let vc = TransactionsListScene.ViewController()
        let transactionsProvider = TransactionsListScene.MovementsProvider(movementsRepo: self.reposController.movementsRepo)
        let transactionsFetcher = TransactionsListScene.PaymentsFetcher(
            transactionsProvider: transactionsProvider,
            ownerAccountId: self.company.accountId,
            currencyIsShown: true
        )
        let emptyActionsProvider = TransactionsListScene.EmptyActionsProvider()
        let amountFormatter = TransactionsListScene.AmountFormatter()
        let dateFormatter = TransactionsListScene.DateFormatter()
        let viewConfig = TransactionsListScene.Model.ViewConfig(actionButtonIsHidden: true)
        
        let routing = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (transactionId, balancId) in
                self?.showTransactionDetailsScreen(
                    transactionsProvider: transactionsProvider,
                    navigationController: navigationController,
                    transactionId: transactionId,
                    balanceId: balancId
                )
            },
            showSendPayment: { _ in },
            showCreateReedeem: { _ in },
            showAcceptRedeem: {},
            showReceive: {},
            showShadow: {
                navigationController.showShadow()
            },
            hideShadow: {
                navigationController.hideShadow()
            })
        TransactionsListScene.Configurator.configure(
            viewController: vc,
            transactionsFetcher: transactionsFetcher,
            actionProvider: emptyActionsProvider,
            amountFormatter: amountFormatter,
            dateFormatter: dateFormatter,
            emptyTitle: Localized(.no_movements),
            viewConfig: viewConfig,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.movements)
        navigationController.setViewControllers([vc], animated: false)
        return navigationController.getViewController()
    }
    
    private func showReceiveScene() {
        let navigationController = NavigationController()
        self.showReceiveScene(navigationController: navigationController)
        self.sideNavigationController.embed(
            centerViewController: navigationController.getViewController()
        )
    }
    
    private func showContribute() {
        guard let contributeAddress = self.flowControllerStack.apiConfigurationModel.contributeUrl,
            let contributeUrl = URL(string: contributeAddress) else {
                return
        }
        UIApplication.shared.open(
            contributeUrl,
            options: [:],
            completionHandler: nil
        )
    }
    
    // MARK: - Sign Out
    
    private func initiateSignOut() {
        let alert = UIAlertController(
            title: Localized(.sign_out),
            message: Localized(.are_you_sure_you_want_to_sign_out),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: Localized(.sign_out_and_erase),
            style: .default,
            handler: { [weak self] _ in
                self?.performSignOut()
        }))
        
        alert.addAction(UIAlertAction(
            title: Localized(.cancel),
            style: .cancel,
            handler: nil
        ))
        
        self.sideNavigationController.present(alert, animated: true, completion: nil)
    }
    
    private func performSignOut() {
        let signOutWorker = RegisterScene.LocalSignInWorker(
            settingsManager: self.managersController.settingsManager,
            userDataManager: self.managersController.userDataManager,
            keychainManager: self.managersController.keychainManager
        )
        
        signOutWorker.performSignOut(completion: { [weak self] in
            self?.onSignOut()
        })
    }
    
    // MARK: - Timeout management
    
    private func startUserActivityTimer() {
        TimerUIApplication.startIdleTimer()
    }
    
    private func stopUserActivityTimer() {
        TimerUIApplication.stopIdleTimer()
    }
    
    private func startBackgroundTimer() {
        self.backgroundToken = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        self.backgroundTimer = Timer.scheduledTimer(
            withTimeInterval: CompaniesListFlowController.backgroundTimeout,
            repeats: false,
            block: { [weak self] _ in
                self?.isAuthorized = false
                self?.stopBackgroundTimer()
        })
    }
    
    private func stopBackgroundTimer() {
        self.backgroundTimer?.invalidate()
        self.backgroundTimer = nil
        UIApplication.shared.endBackgroundTask(self.backgroundToken)
        self.backgroundToken = UIBackgroundTaskIdentifier.invalid
    }
    
    private func checkIsAuthorized() -> Bool {
        if !self.isAuthorized && UIApplication.shared.applicationState == .active {
            self.runLocalAuthByTimeout()
            return false
        }
        
        return true
    }
    
    private func runLocalAuthByTimeout() {
        guard self.localAuthFlow == nil else {
            return
        }
        
        let flow = LocalAuthFlowController(
            account: self.userDataProvider.account,
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            rootNavigation: self.rootNavigation,
            userDataManager: self.managersController.userDataManager,
            keychainManager: self.managersController.keychainManager,
            onAuthorized: { [weak self] in
                self?.onLocalAuthSucceded()
            },
            onRecoverySucceeded: { [weak self] in
                self?.onLocalAuthRecoverySucceeded()
            },
            onSignOut: { [weak self] in
                self?.onSignOut()
            },
            onKYCFailed: {}
        )
        self.localAuthFlow = flow
        flow.run(showRootScreen: nil)
    }
    
    private func onLocalAuthSucceded() {
        self.isAuthorized = true
        self.localAuthFlow = nil
        self.showHomeScreen()
        self.startUserActivityTimer()
    }
}
