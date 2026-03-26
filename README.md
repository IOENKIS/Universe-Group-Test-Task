# GIF Browser — Universe Group Test Task

A minimalist iOS app for browsing, searching, and saving GIFs powered by the [Giphy API](https://developers.giphy.com/).

---

## Requirements

| | |
|---|---|
| **Platform** | iOS 16.0+ |
| **Language** | Swift 5.9 |
| **UI Framework** | UIKit (programmatic layout, no Storyboard logic) |
| **Architecture** | MVVM |
| **Dependencies** | None (zero third-party frameworks) |

---

## Features

### Tab 1 — Gallery
- Loads trending GIFs on launch (25 items per page, infinite scroll)
- Real-time **search** via the Giphy Search API
- **2-column grid** layout built with `UICollectionViewCompositionalLayout`
- Add / remove items from **Favorites** via a heart button on each cell
- **Delete** items from the gallery list
- Empty-state label when no results are found

### Tab 2 — Favorites
- Displays all saved GIFs in the same **2-column grid**
- Remove items from Favorites via a trash button
- Empty-state view with icon and hint text when the list is empty
- Persisted across app launches via **UserDefaults**

### Detail View (both tabs)
- Full-screen animated GIF playback
- **Swipe-down** to dismiss with rubber-band resistance and backdrop fade
- **Pinch-to-zoom** and **double-tap** to zoom in/reset (up to 4×)
- **Share** button — shares the GIF image and its direct URL
- Smooth spring **present / dismiss** animations

---

## Architecture

```
TestTask/
├── Models/
│   ├── GifItem.swift          — Codable model for a single GIF
│   └── GifResponse.swift      — Top-level Giphy API response
│
├── ViewModels/
│   ├── GalleryViewModel.swift  — Trending/search, pagination, favorites toggle
│   └── FavoritesViewModel.swift— Reads from FavoritesStorage, handles removal
│
├── Controllers/
│   ├── MainTabBarController.swift
│   ├── GalleryViewController.swift
│   ├── FavoritesViewController.swift
│   └── GifDetailViewController.swift
│
├── Views/
│   └── GifCell.swift           — Reusable cell with favorite + delete buttons
│
├── Services/
│   ├── NetworkService.swift    — Generic URLSession wrapper with async/await
│   ├── GiphyService.swift      — Trending & search endpoints
│   ├── ImageLoader.swift       — Async image loader with NSCache + GIF decoding
│   └── FavoritesStorage.swift  — UserDefaults persistence with in-memory cache
│
└── Repository/
    └── GifRepository.swift     — Protocol-based data layer (mockable for tests)
```

**Data flow:** `ViewController` → calls methods on `ViewModel` → `ViewModel` uses `Repository` / `Storage` → notifies `ViewController` via closure bindings (`onItemsUpdated`, `onError`, `onLoadingChanged`).

---

## Technical Highlights

- **Swift Concurrency** — all network and image loading calls use `async/await`; `@MainActor` on ViewModels ensures UI updates happen on the main thread.
- **Animated GIF decoding** — `ImageLoader` uses `ImageIO` to decode per-frame delays and compose an animated `UIImage`, without any external library.
- **NSCache image cache** — 150-item / 80 MB cap; duplicate in-flight requests for the same URL are coalesced into a single `Task`.
- **Pagination** — Gallery pre-fetches the next page when the user is within 4 cells of the end of the list.
- **Safe batch deletions** — `IndexPath` is resolved at tap time (not captured at cell configuration) to avoid stale-index crashes after multiple deletions.
- **Background persistence** — `FavoritesStorage` writes to `UserDefaults` on a serial utility queue so the main thread is never blocked.

---

## Getting Started

1. Clone the repository.
2. Open `TestTask.xcodeproj` in Xcode 15 or later.
3. Select a simulator or device running iOS 16.0+.
4. Build and run (`⌘R`).

> The project uses a bundled Giphy API key and requires an active internet connection to load content.

---

## Author

**Ivan Kisilov** — iOS Developer
Developed as a test task for Universe Group · March 2026
