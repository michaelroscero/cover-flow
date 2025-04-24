//
//  ViewController.swift
//  ThreeDCoverFlow
//
//  Created by Michael Rosas Ceronio on 4/17/25.
//

// ViewController.swift
import UIKit
import UIImageColors

struct Track {
    let id: String
    let title: String
    let album: String
    let artist: String
    let albumArtURL: URL

    init?(from json: [String: Any]) {
        guard let id = json["id"] as? String,
              let name = json["name"] as? String,
              let album = json["album"] as? [String: Any],
              let albumName = album["name"] as? String,
              let artists = json["artists"] as? [[String: Any]],
              let firstArtist = artists.first,
              let artistName = firstArtist["name"] as? String,
              let images = album["images"] as? [[String: Any]],
              let firstImage = images.first,
              let urlStr = firstImage["url"] as? String,
              let url = URL(string: urlStr) else {
            return nil
        }
        self.id = id
        self.title = name
        self.album = albumName
        self.artist = artistName
        self.albumArtURL = url
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var coverFlowView: UICollectionView!

    var tracks: [Track] = []
    var lastTrackID: String?
    let backgroundView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundView.frame = view.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(backgroundView, at: 0)

        let layout = CoverFlowLayout()
        coverFlowView.collectionViewLayout = layout
        coverFlowView.decelerationRate = .fast
        coverFlowView.isPagingEnabled = false
        coverFlowView.dataSource = self
        coverFlowView.delegate = self
        coverFlowView.backgroundColor = .clear

        SpotifyAuthManager.shared.startSpotifyLogin()
        if UserDefaults.standard.string(forKey: "access_token") == nil {
            SpotifyAuthManager.shared.startSpotifyLogin()
        } else {
            startPolling()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(startPolling), name: Notification.Name("SpotifyAuthorized"), object: nil)
    }

    @objc func startPolling() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.fetchCurrentlyPlayingTrack()
        }
    }

    func fetchCurrentlyPlayingTrack() {
        guard let accessToken = UserDefaults.standard.string(forKey: "access_token") else {
            print("No access token")
            return
        }

        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let item = json["item"] as? [String: Any],
                  let newTrack = Track(from: item) else {
                print("Failed to parse currently playing track")
                return
            }

            DispatchQueue.main.async {
                if self.lastTrackID != newTrack.id {
                    self.updatePlaybackTracks(with: newTrack)
                }
            }
        }.resume()
    }

    func updatePlaybackTracks(with currentTrack: Track) {
        guard lastTrackID != currentTrack.id else { return }
        lastTrackID = currentTrack.id

        if tracks.count > 0 && tracks.last?.id != currentTrack.id {
            tracks.removeFirst()
        }

        if !tracks.contains(where: { $0.id == currentTrack.id }) {
            tracks.append(currentTrack)
        }

        tracks = Array(tracks.suffix(2))
        coverFlowView.reloadData()

        if let index = tracks.firstIndex(where: { $0.id == lastTrackID }) {
            let indexPath = IndexPath(item: index, section: 0)
            coverFlowView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.updateCenterBackground()
            }
        }

        fetchNextTrack()
    }

    func fetchNextTrack() {
        guard let accessToken = UserDefaults.standard.string(forKey: "access_token") else { return }

        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/queue")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let queue = json["queue"] as? [[String: Any]],
                  let first = queue.first,
                  let nextTrack = Track(from: first) else {
                print("Failed to parse queue")
                return
            }

            DispatchQueue.main.async {
                guard !self.tracks.contains(where: { $0.id == nextTrack.id }) else {
                    print("Skipping duplicate next track")
                    return
                }

                self.tracks.append(nextTrack)
                self.tracks = Array(self.tracks.suffix(3))

                self.coverFlowView.reloadData()
            }
        }.resume()
    }

    func updateCenterBackground() {
        let center = CGPoint(x: coverFlowView.bounds.midX, y: coverFlowView.bounds.midY)
        let point = coverFlowView.convert(center, to: coverFlowView)
        guard let indexPath = coverFlowView.indexPathForItem(at: point),
              let cell = coverFlowView.cellForItem(at: indexPath) as? AlbumCoverCell,
              let image = cell.albumImageView.image else { return }

        updateBackgroundColor(with: image)
    }

    func updateBackgroundColor(with image: UIImage) {
        image.getColors { optionalColors in
            guard let colors = optionalColors else { return }
            DispatchQueue.main.async {
                let gradient = CAGradientLayer()
                gradient.frame = self.backgroundView.bounds
                gradient.colors = [colors.primary.cgColor, colors.secondary.cgColor]
                gradient.startPoint = CGPoint(x: 0, y: 0)
                gradient.endPoint = CGPoint(x: 1, y: 1)

                self.backgroundView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                self.backgroundView.layer.insertSublayer(gradient, at: 0)
            }
        }
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tracks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCoverCell", for: indexPath) as! AlbumCoverCell
        let track = tracks[indexPath.item]
        
        // Always load album image
        cell.albumImageView.loadImage(from: track.albumArtURL.absoluteString) { image in
            if let image = image, indexPath.item == self.tracks.firstIndex(where: { $0.id == self.lastTrackID }) {
                self.updateBackgroundColor(with: image)
            }
        }

        // Clear all labels first
        cell.configureLabels(title: "", album: "", artist: "")

        // Only configure labels for center cell
        let center = CGPoint(x: collectionView.bounds.midX, y: collectionView.bounds.midY)
        let point = collectionView.convert(center, to: collectionView)
        if let visibleIndexPath = collectionView.indexPathForItem(at: point),
           visibleIndexPath.item == indexPath.item {
            cell.configureLabels(title: track.title, album: track.album, artist: track.artist)
        }

        return cell
    }
}
