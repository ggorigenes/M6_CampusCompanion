import CoreLocation
import MapKit
import UIKit

class DetailViewController: UIViewController, CLLocationManagerDelegate {

    private enum CampusLocation {
        static let coordinate = CLLocationCoordinate2D(
            latitude: 14.60412,
            longitude: 120.98862
        )
    }

    private enum ManilaCampusLocation {
        static let coordinate = CLLocationCoordinate2D(
            latitude: 14.60350,
            longitude: 120.98750
        )
    }

    private let locationManager = CLLocationManager()

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var campusMapView: MKMapView!
    @IBOutlet weak var messageLabel: UILabel!

    var studentName: String = ""
    var notificationsEnabled: Bool = false
    var selectedRole: String = ""
    var eventDate: Date = Date()
    var guestCount: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Force the label to use multiple lines
        distanceLabel.numberOfLines = 0
        distanceLabel.lineBreakMode = .byWordWrapping

        // 2. Disconnect it from the Storyboard's broken constraints
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false

        // 3. Lock it to the left and right edges of the screen
        NSLayoutConstraint.activate([
            distanceLabel.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 20
            ),
            distanceLabel.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -20
            ),
            distanceLabel.topAnchor.constraint(
                equalTo: campusMapView.bottomAnchor,
                constant: 20
            ),
        ])
        title = "Campus Events"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let formattedDate = dateFormatter.string(from: eventDate)

        let notificationStatus = notificationsEnabled ? "on" : "off"

        messageLabel.text =
            "Welcome, \(studentName)! (\(selectedRole)) Notifications: \(notificationStatus).\n\nEvent Date: \(formattedDate)\nGuests: \(guestCount)"

        let region = MKCoordinateRegion(
            center: CampusLocation.coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        campusMapView.setRegion(region, animated: false)

        let annotation = MKPointAnnotation()
        annotation.coordinate = CampusLocation.coordinate
        annotation.title = "FEU Tech Campus"
        campusMapView.addAnnotation(annotation)

        let manilaAnnotation = MKPointAnnotation()
        manilaAnnotation.coordinate = ManilaCampusLocation.coordinate
        manilaAnnotation.title = "FEU Manila Campus"
        campusMapView.addAnnotation(manilaAnnotation)

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            distanceLabel.text = "Location access denied."
        default:
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let currentLocation = locations.first else { return }

        let campusLocation = CLLocation(
            latitude: CampusLocation.coordinate.latitude,
            longitude: CampusLocation.coordinate.longitude
        )

        let distanceInMeters = currentLocation.distance(from: campusLocation)

        distanceLabel.text = String(
            format: "You are approximately %.0f meters from campus.",
            distanceInMeters
        )
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("Location update failed: \(error.localizedDescription)")
    }

}
