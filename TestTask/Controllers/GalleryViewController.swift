//
//  GalleryViewController.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import UIKit

// MARK: - GalleryViewController

final class GalleryViewController: UIViewController {

    // MARK: - ViewModel

    private let viewModel = GalleryViewModel()

    // MARK: - UI

    private lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search GIFs…"
        sb.searchBarStyle = .minimal
        sb.delegate = self
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

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

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private lazy var emptyStateLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No GIFs found"
        lbl.textColor = .secondaryLabel
        lbl.font = .systemFont(ofSize: 17, weight: .medium)
        lbl.textAlignment = .center
        lbl.isHidden = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.loadInitial()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh only the favorite icon for each visible cell — avoids full reloadData() flicker
        collectionView.indexPathsForVisibleItems.forEach { indexPath in
            guard let cell = collectionView.cellForItem(at: indexPath) as? GifCell else { return }
            cell.setFavorite(viewModel.isFavorite(at: indexPath.item))
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Gallery"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onItemsUpdated = { [weak self] in
            guard let self else { return }
            self.collectionView.reloadData()
            self.emptyStateLabel.isHidden = !self.viewModel.items.isEmpty
        }

        viewModel.onLoadingChanged = { [weak self] isLoading in
            if isLoading {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
            }
        }

        viewModel.onError = { [weak self] message in
            self?.showError(message)
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

    // MARK: - Error handling

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.viewModel.loadInitial()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension GalleryViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GifCell.reuseID, for: indexPath) as! GifCell
        let item = viewModel.items[indexPath.item]
        cell.configure(with: item, isFavorite: viewModel.isFavorite(at: indexPath.item))
        cell.delegate = self
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension GalleryViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        viewModel.loadNextPageIfNeeded(indexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let item = viewModel.items[indexPath.item]
        present(GifDetailViewController(item: item), animated: false)
    }
}

// MARK: - GifCellDelegate

extension GalleryViewController: GifCellDelegate {

    func gifCellDidTapFavorite(_ cell: GifCell) {
        // Resolve live IndexPath at tap time — avoids stale-index issues after deletions
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        viewModel.toggleFavorite(at: indexPath.item)
        cell.setFavorite(viewModel.isFavorite(at: indexPath.item))
    }

    func gifCellDidTapDelete(_ cell: GifCell) {
        // Resolve live IndexPath at tap time — avoids stale-index issues after deletions
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        viewModel.removeItem(at: indexPath.item)
        collectionView.performBatchUpdates {
            self.collectionView.deleteItems(at: [indexPath])
        } completion: { [weak self] _ in
            guard let self else { return }
            self.emptyStateLabel.isHidden = !self.viewModel.items.isEmpty
        }
    }
}

// MARK: - UISearchBarDelegate

extension GalleryViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        viewModel.search(query: searchBar.text ?? "")
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            viewModel.loadInitial()
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        viewModel.loadInitial()
    }
}
