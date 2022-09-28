//
//  AppDelegate.swift
//  PopCornCine
//
//  Created by Артем Билый on 27.09.2022.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var splashPresenter: SplashPresenterDescription? = SplashPresenter()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        splashPresenter?.present()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.splashPresenter?.dismiss { [weak self] in
                self?.splashPresenter = nil
            }
        }
        return true
    }
}

