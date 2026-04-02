//
//  GifCell.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//

import UIKit

// MARK: - GifCellDelegate
//
// The delegate receives the cell itself — NOT a stored IndexPath.
// The ViewController resolves the live IndexPath via collectionView.indexPath(for:)
// at the moment of the tap, which prevents stale-index crashes when items are
// deleted quickly and cells are shifted before the next tap fires.

protocol GifCellDelegate: AnyObject {
    func gifCellDidTapFavorite(_ cell: GifCell)
    func gifCellDidTapDelete(_ cell: GifCell)
}

// MARK: - GifCell

final class GifCell: UICollectionViewCell {

    static let reuseID = "GifCell"

    // MARK: - Delegate

    weak var delegate: GifCellDelegate?

    // MARK: - UI

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.alpha = 0
        return iv
    }()

    private let shimmerView: UIView = {
        let v = UIView()
        v.backgroundColor = .tertiarySystemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var favoriteButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "heart"), for: .normal)
        btn.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var deleteButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "trash"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        return btn
    }()
    
    private let errorImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "photo.badge.exclamationmark")
        iv.tintColor = .systemGray
        iv.contentMode = .center
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        iv.alpha = 0
        return iv
    }()

    // MARK: - Image loading

    private var imageTask: Task<Void, Never>?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        imageView.image = nil
        imageView.alpha = 0
        errorImageView.isHidden = true
        errorImageView.alpha = 0
        shimmerView.isHidden = false
        startShimmer()
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        contentView.addSubview(shimmerView)
        contentView.addSubview(imageView)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            shimmerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            favoriteButton.widthAnchor.constraint(equalToConstant: 32),
            favoriteButton.heightAnchor.constraint(equalToConstant: 32),

            deleteButton.topAnchor.constraint(equalTo: favoriteButton.bottomAnchor, constant: 6),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            deleteButton.widthAnchor.constraint(equalToConstant: 32),
            deleteButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        startShimmer()
    }

    // MARK: - Configure

    func configure(with item: GifItem, isFavorite: Bool, showFavoriteButton: Bool = true, showDeleteButton: Bool = true) {
        favoriteButton.isSelected = isFavorite
        favoriteButton.tintColor = .white
        favoriteButton.backgroundColor = isFavorite ? .systemRed : UIColor.black.withAlphaComponent(0.35)
        favoriteButton.isHidden = !showFavoriteButton
        deleteButton.isHidden = !showDeleteButton

        guard let url = item.previewURL else { return }
        loadImage(from: url)
    }

    // MARK: - Image loading

    private func loadImage(from url: URL) {
        errorImageView.isHidden = true
        errorImageView.alpha = 0
        imageTask = Task { [weak self] in
            guard let self else { return }
            do {
                let image = try await ImageLoader.shared.loadImage(from: url)
                guard !Task.isCancelled else { return }
                self.shimmerView.isHidden = true
                self.stopShimmer()
                self.imageView.image = image
                UIView.animate(withDuration: 0.25) {
                    self.imageView.alpha = 1
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.shimmerView.isHidden = true
                self.stopShimmer()
                
                self.errorImageView.isHidden = false
                UIView.animate(withDuration: 0.3) {
                    self.errorImageView.alpha = 1
                }
            }
        }
    }

    // MARK: - Shimmer

    private func startShimmer() {
        shimmerView.isHidden = false
        shimmerView.layer.sublayers?.filter { $0.name == "shimmer" }.forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        gradient.name = "shimmer"
        gradient.colors = [
            UIColor.tertiarySystemBackground.cgColor,
            UIColor.secondarySystemBackground.cgColor,
            UIColor.tertiarySystemBackground.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.locations  = [-1, -0.5, 0]
        gradient.frame      = bounds

        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue    = [-1, -0.5, 0]
        anim.toValue      = [1, 1.5, 2]
        anim.repeatCount  = .infinity
        anim.duration     = 1.2
        gradient.add(anim, forKey: "shimmerAnim")
        shimmerView.layer.addSublayer(gradient)
    }

    private func stopShimmer() {
        shimmerView.layer.sublayers?.filter { $0.name == "shimmer" }.forEach { $0.removeFromSuperlayer() }
    }

    // MARK: - Actions

    @objc private func favoriteTapped() {
        delegate?.gifCellDidTapFavorite(self)
    }

    @objc private func deleteTapped() {
        delegate?.gifCellDidTapDelete(self)
    }

    // MARK: - Update favorite state

    func setFavorite(_ isFavorite: Bool) {
        favoriteButton.isSelected = isFavorite
        UIView.animate(withDuration: 0.2) {
            self.favoriteButton.tintColor = .white
            self.favoriteButton.backgroundColor = isFavorite ? .systemRed : UIColor.black.withAlphaComponent(0.35)
            self.favoriteButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.favoriteButton.transform = .identity
            }
        }
    }
}
