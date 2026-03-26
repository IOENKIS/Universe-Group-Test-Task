//
//  FavoritesViewController.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import UIKit

// MARK: - FavoritesViewController

final class FavoritesViewController: UIViewController {

    // MARK: - ViewModel

    private let viewModel = FavoritesViewModel()

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .systemBackground
        cv.register(GifCell.self, forCellWithReuseIdentifier: GifCell.reuseID)
        cv.dataSource = self
        cv.delegate = self
        cv.alwaysBounceVertical = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private lazy var emptyStateView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true

        let imageView = UIImageView(image: UIImage(systemName: "heart.slash"))
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "No favorites yet"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let sub = UILabel()
        sub.text = "Tap ♥ on any GIF to save it here"
        sub.textColor = .tertiaryLabel
        sub.font = .systemFont(ofSize: 14)
        sub.textAlignment = .center
        sub.translatesAutoresizingMaskIntoConstraints = false

        v.addSubview(imageView)
        v.addSubview(label)
        v.addSubview(sub)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: v.centerYAnchor, constant: -40),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: v.centerXAnchor),

            sub.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
            sub.centerXAnchor.constraint(equalTo: v.centerXAnchor)
        ])

        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reloadFavorites()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Favorites"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        view.addSubview(collectionView)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onItemsUpdated = { [weak self] in
            guard let self else { return }
            self.collectionView.reloadData()
            self.emptyStateView.isHidden = !self.viewModel.items.isEmpty
        }
    }

    // MARK: - Layout

    private func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalWidth(0.5)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(0.5)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - UICollectionViewDataSource

extension FavoritesViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GifCell.reuseID, for: indexPath) as! GifCell
        let item = viewModel.items[indexPath.item]
        // In Favorites tab: heart is always filled (all are favorites), show only delete
        cell.configure(with: item, isFavorite: true, showFavoriteButton: false, showDeleteButton: true)
        cell.indexPath = indexPath
        cell.delegate = self
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension FavoritesViewController: UICollectionViewDelegate {}

// MARK: - GifCellDelegate

extension FavoritesViewController: GifCellDelegate {

    func gifCell(_ cell: GifCell, didTapFavoriteAt indexPath: IndexPath) {
        // Not shown in Favorites tab, but protocol requires implementation
    }

    func gifCell(_ cell: GifCell, didTapDeleteAt indexPath: IndexPath) {
        viewModel.removeItem(at: indexPath.item)
        collectionView.performBatchUpdates {
            collectionView.deleteItems(at: [indexPath])
        } completion: { [weak self] _ in
            guard let self else { return }
            self.emptyStateView.isHidden = !self.viewModel.items.isEmpty
        }
    }
}
