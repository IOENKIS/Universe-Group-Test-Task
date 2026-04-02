//
//  GifDetailViewController.swift
//  TestTask
//
//  Created by Ivan Kisilov on 26.03.2026.
//
//  Full-screen animated GIF viewer (Gifchan-inspired).
//  Features:
//    • Plays the animated GIF at original quality
//    • Swipe-down (with rubber-band effect) to dismiss
//    • Double-tap or pinch to zoom (UIScrollView)
//    • Share sheet via the top-right button
//    • Smooth scale+fade present / dismiss animations

import UIKit

// MARK: - GifDetailViewController

final class GifDetailViewController: UIViewController {

    // MARK: - Properties

    private let item: GifItem
    private var imageTask: Task<Void, Never>?

    // Tracks the view's Y-origin when a pan begins so we can compute relative translation
    private var panStartTranslationY: CGFloat = 0

    // MARK: - UI

    /// Solid black backdrop that fades with the swipe-down gesture
    private let backdropView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 4.0
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.color = .white
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var shareButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        btn.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var favoriteButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        btn.setImage(UIImage(systemName: "heart", withConfiguration: config), for: .normal)
        btn.setImage(UIImage(systemName: "heart.fill", withConfiguration: config), for: .selected)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        return btn
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = UIColor.white.withAlphaComponent(0.75)
        lbl.font = .systemFont(ofSize: 13, weight: .medium)
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    /// Pill-shaped "swipe to close" hint that appears below the image
    private let swipeHintLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Swipe down to close"
        lbl.textColor = UIColor.white.withAlphaComponent(0.35)
        lbl.font = .systemFont(ofSize: 12, weight: .regular)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - Init

    init(item: GifItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { imageTask?.cancel() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        loadGif()
        updateFavoriteState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Start invisible + slightly scaled down; animate in viewDidAppear
        backdropView.alpha = 0
        scrollView.alpha = 0
        scrollView.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        closeButton.alpha  = 0
        shareButton.alpha  = 0
        favoriteButton.alpha = 0
        titleLabel.alpha   = 0
        swipeHintLabel.alpha = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(
            withDuration: 0.38,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.4,
            options: []
        ) {
            self.backdropView.alpha = 1
            self.scrollView.alpha   = 1
            self.scrollView.transform = .identity
            self.closeButton.alpha  = 1
            self.shareButton.alpha  = 1
            self.favoriteButton.alpha = 1
            self.titleLabel.alpha   = 1
        }
        UIView.animate(withDuration: 0.6, delay: 0.5) {
            self.swipeHintLabel.alpha = 1
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .clear
        titleLabel.text = item.title.isEmpty ? "GIF" : item.title

        view.addSubview(backdropView)
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(activityIndicator)
        view.addSubview(closeButton)
        view.addSubview(shareButton)
        view.addSubview(favoriteButton)
        view.addSubview(titleLabel)
        view.addSubview(swipeHintLabel)

        scrollView.delegate = self

        NSLayoutConstraint.activate([
            // Backdrop — full screen
            backdropView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ScrollView — full screen
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ImageView: pinned to all 4 edges of contentLayoutGuide (sets scrollable content size)
            // + matched to frameLayoutGuide size so content == viewport at 1× zoom.
            // contentMode .scaleAspectFit then centres & scales the GIF within the full-screen frame.
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),

            // Spinner
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Close (top-left)
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            // Share (top-right)
            shareButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            shareButton.widthAnchor.constraint(equalToConstant: 40),
            shareButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Favorite (left from share button)
            favoriteButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            favoriteButton.trailingAnchor.constraint(equalTo: shareButton.leadingAnchor, constant: -12),
            favoriteButton.widthAnchor.constraint(equalToConstant: 40),
            favoriteButton.heightAnchor.constraint(equalToConstant: 40),

            // Title (bottom)
            titleLabel.bottomAnchor.constraint(equalTo: swipeHintLabel.topAnchor, constant: -6),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Swipe hint (very bottom)
            swipeHintLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            swipeHintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Gestures

    private func setupGestures() {
        // Swipe-down to dismiss
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)

        // Double-tap to zoom / reset
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    // MARK: - Loading

    private func loadGif() {
        activityIndicator.startAnimating()
        // Prefer original URL for best quality; fall back to preview
        guard let url = item.originalURL ?? item.previewURL else {
            activityIndicator.stopAnimating()
            return
        }

        imageTask = Task { [weak self] in
            guard let self else { return }
            do {
                let image = try await ImageLoader.shared.loadImage(from: url)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.imageView.image = image
                    UIView.animate(withDuration: 0.25) { self.imageView.alpha = 1 }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { self.activityIndicator.stopAnimating() }
            }
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismissAnimated()
    }

    @objc private func shareTapped() {
        var shareItems: [Any] = []
        if let image = imageView.image { shareItems.append(image) }
        if let url = item.originalURL    { shareItems.append(url) }
        guard !shareItems.isEmpty else { return }

        let ac = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        ac.popoverPresentationController?.sourceView = shareButton
        present(ac, animated: true)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let rect  = CGRect(x: point.x - 60, y: point.y - 60, width: 120, height: 120)
            scrollView.zoom(to: rect, animated: true)
        }
    }
    
    @objc private func favoriteTapped() {
        let willBeFavorite = !favoriteButton.isSelected
        
        FavoritesStorage.shared.toggle(item)
        
        UIView.animate(withDuration: 0.2, animations: {
            self.favoriteButton.isSelected = willBeFavorite
            self.favoriteButton.backgroundColor = willBeFavorite ?
                .systemRed.withAlphaComponent(0.8) :
                .white.withAlphaComponent(0.18)
            
            self.favoriteButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.favoriteButton.transform = .identity
            }
        }
        
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - Pan gesture (swipe-down to dismiss)

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity    = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            panStartTranslationY = 0

        case .changed:
            // Rubber-band: resist negative (upward) translation slightly
            let rawY    = translation.y
            let dampedY = rawY > 0 ? rawY : rawY * 0.25
            let progress = abs(dampedY) / view.bounds.height

            view.transform = CGAffineTransform(translationX: 0, y: dampedY)

            // Fade backdrop as user drags; clamp so it never goes below 0.15
            backdropView.alpha = max(0.15, 1.0 - progress * 1.8)

            // Slightly scale down to give depth
            let scale = max(0.80, 1.0 - progress * 0.22)
            view.transform = CGAffineTransform(translationX: 0, y: dampedY)
                .concatenating(CGAffineTransform(scaleX: scale, y: scale))

        case .ended, .cancelled:
            let shouldDismiss = translation.y > 110 || velocity.y > 650
            if shouldDismiss {
                let direction: CGFloat = translation.y >= 0 ? 1 : -1
                throwDismiss(direction: direction, velocity: velocity.y)
            } else {
                UIView.animate(
                    withDuration: 0.4,
                    delay: 0,
                    usingSpringWithDamping: 0.7,
                    initialSpringVelocity: 0.3
                ) {
                    self.view.transform  = .identity
                    self.backdropView.alpha = 1
                }
            }

        default:
            break
        }
    }

    // MARK: - Dismiss Animations

    /// Called by close button and double-threshold swipe
    private func dismissAnimated() {
        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: .curveEaseIn
        ) {
            self.view.alpha     = 0
            self.view.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
            self.backdropView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }

    /// Called when the swipe-down threshold is met — throws the view off-screen
    private func throwDismiss(direction: CGFloat, velocity: CGFloat) {
        let distance = view.bounds.height
        let duration = max(0.18, min(0.32, distance / abs(velocity)))

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseIn
        ) {
            self.view.transform     = CGAffineTransform(translationX: 0, y: direction * distance * 1.1)
            self.backdropView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
    
    // MARK: - Helpers
    
    private func updateFavoriteState() {
        let isFav = FavoritesStorage.shared.isFavorite(item)
        favoriteButton.isSelected = isFav
        // Якщо вибрано — робимо кнопку червоною, якщо ні — напівпрозорою білою
        favoriteButton.backgroundColor = isFav ?
            .systemRed.withAlphaComponent(0.8) :
            .white.withAlphaComponent(0.18)
    }
}

// MARK: - UIScrollViewDelegate

extension GifDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Keep the image centred when smaller than the viewport after zoom
        let offsetX = max((scrollView.bounds.width  - scrollView.contentSize.width)  * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension GifDetailViewController: UIGestureRecognizerDelegate {
    /// Allow the dismiss-pan only when:
    ///  • The scroll view is at 1× zoom (not in a zoom session)
    ///  • The gesture is primarily downward
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        guard scrollView.zoomScale == 1.0 else { return false }
        let v = pan.velocity(in: view)
        return v.y > 0 && abs(v.y) > abs(v.x)
    }
}
