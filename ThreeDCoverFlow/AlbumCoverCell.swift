//
//  AlbumCell.swift
//  ThreeDCoverFlow
//
//  Created by Michael Rosas Ceronio on 4/17/25.
//

import UIKit

class AlbumCoverCell: UICollectionViewCell {
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear

        // Responsive label formatting
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.numberOfLines = 1

        albumLabel.adjustsFontSizeToFitWidth = true
        albumLabel.minimumScaleFactor = 0.5
        albumLabel.numberOfLines = 1

        artistLabel.adjustsFontSizeToFitWidth = true
        artistLabel.minimumScaleFactor = 0.5
        artistLabel.numberOfLines = 1
        
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        artistLabel.text = nil
        albumLabel.text = nil
        albumImageView.image = nil
    }

    func configureLabels(title: String, album: String, artist: String) {
        titleLabel.text = title
        albumLabel.text = album
        artistLabel.text = artist
    }
}

extension UIImageView {
    func loadImage(from urlString: String, completion: ((UIImage?) -> Void)? = nil) {
        guard let url = URL(string: urlString) else {
            completion?(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                  let image = UIImage(data: data), error == nil else {
                completion?(nil)
                return
            }

            DispatchQueue.main.async {
                self.image = image
                completion?(image)
            }
        }.resume()
    }
}
