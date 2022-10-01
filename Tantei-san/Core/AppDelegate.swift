//
//  AppDelegate.swift
//  Tantei-san
//
//  Created by Randell on 28/9/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setupSettings()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        appCoordinator = AppCoordinator(window: window!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.appCoordinator.start()
        }
        
        return true
    }
    
    private func setupSettings() {
        let appInfo = Bundle.main.infoDictionary ?? [:]
        let shortVersionString = appInfo["CFBundleShortVersionString"] as? String ?? ""
        let bundleVersion = appInfo["CFBundleVersion"] as? String ?? ""
        let defaults = UserDefaults.standard
        defaults.set(shortVersionString, forKey: "application_version")
        defaults.set(bundleVersion, forKey: "application_build")
    }
}

