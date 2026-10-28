import CoreData
import UIKit

private enum RemoteEndpoint {
    static let announcements = URL(
        string:
            "https://gist.githubusercontent.com/ggorigenes/968acafca903c4571acdc949c81cb6d6/raw/announcements.json"
    )!
}

class AnnouncementsViewController: UITableViewController {
    private var announcements: [CampusAnnouncement] = []

    private var context: NSManagedObjectContext {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer
            .viewContext
    }

    @IBAction func refreshTapped(_ sender: Any) {
        fetchAnnouncementsFromServer()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Campus Announcements"

        seedInitialAnnouncementsIfNeeded()
        loadAnnouncements()
    }

    func fetchAnnouncementsFromServer() {
        let task = URLSession.shared.dataTask(
            with: RemoteEndpoint.announcements
        ) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode)
            else {
                print("Unexpected server response.")
                return
            }
            guard let data = data else { return }
            print("Reached network handler with \(data.count) bytes.")
            do {
                let decoder = JSONDecoder()
                let decodedAnnouncements = try decoder.decode(
                    [AnnouncementDTO].self,
                    from: data
                )

                DispatchQueue.main.async {
                    self.replaceAnnouncements(with: decodedAnnouncements)
                    self.showNetworkConfirmationAlert(byteCount: data.count)
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }
        task.resume()
    }

    func showNetworkConfirmationAlert(byteCount: Int) {
        let alert = UIAlertController(
            title: "Server Reached",
            message:
                "Received \(byteCount) bytes from the announcements endpoint.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func replaceAnnouncements(with dtos: [AnnouncementDTO]) {
        let deleteRequest: NSFetchRequest<CampusAnnouncement> =
            CampusAnnouncement.fetchRequest()
        let existing = (try? context.fetch(deleteRequest)) ?? []
        for item in existing { context.delete(item) }

        for dto in dtos {
            let announcement = CampusAnnouncement(context: context)
            announcement.title = dto.title
            announcement.date = dto.date
            announcement.category = dto.category
            announcement.location = dto.location
            announcement.priorityLevel = dto.priorityLevel
        }

        try? context.save()
        loadAnnouncements()
        tableView.reloadData()
    }

    private func seedInitialAnnouncementsIfNeeded() {
        let request: NSFetchRequest<CampusAnnouncement> =
            CampusAnnouncement.fetchRequest()
        let existingCount = (try? context.count(for: request)) ?? 0
        guard existingCount == 0 else { return }

        let seedData = [
            ("Enrollment Period Extended", "Registrar", "August 3, 2026"),
            ("Library Hours Extended for Finals", "Library", "August 5, 2026"),
            ("Career Fair 2026", "Career Center", "August 10, 2026"),
            ("Student Council Elections", "Student Affairs", "August 12, 2026"),
            (
                "Campus Wi-Fi Maintenance Notice", "IT Services",
                "August 16, 2026"
            ),
            ("Intramural Sports Sign-Up", "Athletics", "August 20, 2026"),
        ]

        for data in seedData {
            let announcement = CampusAnnouncement(context: context)
            announcement.title = data.0
            announcement.category = data.1
            announcement.date = data.2
        }

        try? context.save()
    }

    private func loadAnnouncements() {
        let request: NSFetchRequest<CampusAnnouncement> =
            CampusAnnouncement.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: true)
        ]
        announcements = (try? context.fetch(request)) ?? []
        tableView.reloadData()
    }

    @IBAction func addAnnouncementTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "New Announcement",
            message: "Enter a title and category.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in textField.placeholder = "Title" }
        alert.addTextField { textField in textField.placeholder = "Category" }

        let saveAction = UIAlertAction(title: "Save", style: .default) {
            [weak self, weak alert] _ in
            guard let self = self,
                let titleText = alert?.textFields?[0].text, !titleText.isEmpty,
                let categoryText = alert?.textFields?[1].text,
                !categoryText.isEmpty
            else { return }

            let newAnnouncement = CampusAnnouncement(context: self.context)
            newAnnouncement.title = titleText
            newAnnouncement.date = DateFormatter.localizedString(
                from: Date(),
                dateStyle: .long,
                timeStyle: .none
            )
            newAnnouncement.category = categoryText

            try? self.context.save()
            self.loadAnnouncements()
        }

        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return announcements.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: "AnnouncementCell",
                for: indexPath
            ) as! AnnouncementCell

        let announcement = announcements[indexPath.row]

        cell.configure(with: announcement)

        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            let announcementToDelete = announcements[indexPath.row]

            context.delete(announcementToDelete)

            try? context.save()

            announcements.remove(at: indexPath.row)

            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
