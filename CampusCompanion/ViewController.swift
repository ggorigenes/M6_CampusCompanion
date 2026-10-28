import PhotosUI
import UIKit

private enum DefaultsKey {
    static let studentName = "studentName"
    static let notificationsEnabled = "notificationsEnabled"
    static let selectedRoleIndex = "selectedRolelndex"
}

class ViewController: UIViewController, PHPickerViewControllerDelegate {

    @IBAction func removePhotoTapped(_ sender: Any) {
        profileImageView.image = UIImage(systemName: "person.crop.circle")

        guard
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        else { return }

        let fileURL = documentsURL.appendingPathComponent("profilePhoto.jpg")

        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print(
                "Could not remove profile photo or no photo existed: \(error.localizedDescription)"
            )
        }
    }

    @IBAction func changePhotoTapped(_ sender: Any) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
            guard let image = object as? UIImage else { return }

            DispatchQueue.main.async {
                self.profileImageView.image = image
                self.saveProfileImageToDisk(image)
            }
        }
    }

    func saveProfileImageToDisk(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8),
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        else { return }

        let fileURL = documentsURL.appendingPathComponent("profilePhoto.jpg")

        do {
            try data.write(to: fileURL)
        } catch {
            print("Could not save profile photo: \(error.localizedDescription)")
        }
    }

    func loadProfileImageFromDisk() {
        guard
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        else { return }

        let fileURL = documentsURL.appendingPathComponent("profilePhoto.jpg")

        if let image = UIImage(contentsOfFile: fileURL.path) {
            profileImageView.image = image
        }
    }

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var roleSegmentedControl: UISegmentedControl!
    @IBOutlet weak var notificationSwitch: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.text =
            UserDefaults.standard.string(forKey: DefaultsKey.studentName) ?? ""
        notificationSwitch.isOn = UserDefaults.standard.bool(
            forKey: DefaultsKey.notificationsEnabled
        )
        roleSegmentedControl.selectedSegmentIndex = UserDefaults.standard
            .integer(forKey: DefaultsKey.selectedRoleIndex)

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    @IBAction func resetPreferencesTapped(_ sender: UIButton) {
        UserDefaults.standard.removeObject(forKey: DefaultsKey.studentName)
        UserDefaults.standard.removeObject(
            forKey: DefaultsKey.notificationsEnabled
        )
        UserDefaults.standard.removeObject(
            forKey: DefaultsKey.selectedRoleIndex
        )

        nameTextField.text = ""
        notificationSwitch.isOn = false
        roleSegmentedControl.selectedSegmentIndex = 0
    }

    @IBOutlet weak var eventDatePicker: UIDatePicker!

    @IBOutlet weak var guestStepper: UIStepper!
    @IBAction func getStarted(_ sender: Any) {
        subtitleLabel.text = "Let's get started!"
    }

    @IBAction func exploreButtonTapped(_ sender: UIButton) {
        nameTextField.resignFirstResponder()

        let enteredName = nameTextField.text ?? ""
        UserDefaults.standard.set(enteredName, forKey: DefaultsKey.studentName)
        UserDefaults.standard.set(
            notificationSwitch.isOn,
            forKey: DefaultsKey.notificationsEnabled
        )
        UserDefaults.standard.set(
            roleSegmentedControl.selectedSegmentIndex,
            forKey: DefaultsKey.selectedRoleIndex
        )

        performSegue(withIdentifier: "ShowDetailSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowDetailSegue",
            let destination = segue.destination as? DetailViewController
        else {
            return
        }

        let enteredName = nameTextField.text ?? ""
        destination.studentName = enteredName.isEmpty ? "Student" : enteredName
        destination.notificationsEnabled = notificationSwitch.isOn
        destination.selectedRole =
            roleSegmentedControl.selectedSegmentIndex == 0
            ? "Student" : "Faculty"
        destination.eventDate = eventDatePicker.date
        destination.guestCount = Int(guestStepper.value)
    }
}
