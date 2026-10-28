import UIKit

class AnnouncementCell: UITableViewCell {

    @IBOutlet weak var categoryIconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    func configure(with announcement: CampusAnnouncement) {
        titleLabel.text = announcement.title
        let loc = announcement.location ?? "Unknown Location"
        let priority = announcement.priorityLevel ?? "Normal"
        dateLabel.text =
            "\(announcement.category ?? "") • \(loc) • Priority: \(priority)"
    }
}
