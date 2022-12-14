//
//  AppDelegate.swift
//  CloudMovies
//
//  Created by Артем Билый on 03.10.2022.
//

import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var splashPresenter: SplashPresenterDescription? = SplashPresenter()
    private let tabBarContoller = TabBarController()
    private let authorizationVC = LoginViewController()
    private let accountVC = AccountViewController()
    private let onboardingViewController = OnboardingContainerViewController()
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UITableView.appearance().tableHeaderView = .init(frame: .init(x: 0,
                                                                      y: 0,
                                                                      width: 0,
                                                                      height: CGFloat.leastNonzeroMagnitude))
        UITabBar.appearance().tintColor = .systemRed
        registerForNotifications()
        splashPresenter?.present()
        onboardingViewController.delegate = self
        authorizationVC.delegate = self
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.backgroundColor = .white
        window?.rootViewController = authorizationVC
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.splashPresenter?.dismiss { [weak self] in
                self?.splashPresenter = nil
            }
        }
        return true
    }
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didLogout), name: .logout, object: nil)
    }
}

extension AppDelegate {
    func setRootViewController(_ viewController: UIViewController, animated: Bool = true) {
        guard animated, let window = self.window else {
            self.window?.rootViewController = viewController
            self.window?.makeKeyAndVisible()
            return
        }
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        UIView.transition(with: window,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
    }
}

extension AppDelegate: LoginViewControllerDelegate {
    func didLogin() {
        if LocalState.hasOnboarded {
            tabBarContoller.selectedIndex = 0
            setRootViewController(onboardingViewController)
        } else {
            setRootViewController(onboardingViewController)
        }
    }
}

extension AppDelegate: OnboardingContainerViewControllerDelegate {
    func didFinishOnboarding() {
        LocalState.hasOnboarded = true
        setRootViewController(tabBarContoller)
    }
}

extension AppDelegate {
    @objc func didLogout() {
        setRootViewController(authorizationVC)
    }
}
