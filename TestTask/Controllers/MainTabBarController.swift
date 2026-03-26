//
//  MainTabBarController.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import UIKit

// MARK: - MainTabBarController

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupTabs()
    }

    // MARK: - Tabs

    private func setupTabs() {
        let galleryVC = GalleryViewController()
        let galleryNav = UINavigationController(rootViewController: galleryVC)
        galleryNav.tabBarItem = UITabBarItem(
            title: "Gallery",
            image: UIImage(systemName: "square.grid.2x2"),
            selectedImage: UIImage(systemName: "square.grid.2x2.fill")
        )

        let favoritesVC = FavoritesViewController()
        let favoritesNav = UINavigationController(rootViewController: favoritesVC)
        favoritesNav.tabBarItem = UITabBarItem(
            title: "Favorites",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )

        viewControllers = [galleryNav, favoritesNav]
    }

    // MARK: - Appearance

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        tabBar.tintColor = .label
        tabBar.unselectedItemTintColor = .tertiaryLabel
    }
}
