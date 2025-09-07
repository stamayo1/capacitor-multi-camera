//
//  Thumbail.swift
//  CapacitorMultiCamera
//
//  Created by Sebastian Tamayo lasso on 6/09/25.
//
class ThumbnailCell: UICollectionViewCell {
    static let identifier = "ThumbnailCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        return iv
    }()

    
    private let removeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var onRemove: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(removeButton)

        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Thumbnail wide spaceß
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Floating remove burron
            removeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -1),
            removeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            removeButton.widthAnchor.constraint(equalToConstant: 25),
            removeButton.heightAnchor.constraint(equalToConstant: 25)
        ])

        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
    }

    @objc private func removeTapped() {
        onRemove?()
    }

    func configure(with image: UIImage) {
        imageView.image = image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}