import AMVKit
import UIKit


class TableViewController: UITableViewController {

    @IBOutlet var refreshButton: UIBarButtonItem!


    private var accessCertificates: [AmvAccessCertificate] = []

    // MARK: IBActions

    @IBAction func refreshButtonTapped(_ sender: UIBarButtonItem) {
        refreshAccessCertificates()
    }


    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accessCertificates.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accessCertificateCell", for: indexPath)
        let accessCertificate = accessCertificates[indexPath.row]

        cell.textLabel?.text = accessCertificate.name
        cell.detailTextLabel?.text = accessCertificate.vehicleSerial

        // Disable the cell when the certificate is expired (or nonValid for current time)
        if !accessCertificate.isValid(Date()) {
            let label = UILabel()

            label.text = "Invalid"
            label.textColor = UIColor.red
            label.font = UIFont.systemFont(ofSize: 12.0)
            label.sizeToFit()

            cell.accessoryView = label
        }

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard accessCertificates[indexPath.row].isValid(Date()) else {
            return nil
        }

        return indexPath
    }


    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            let accessApiContext: AccessApiContext = try ApplicationPropertiesReader.createProperties(fromPropertyList: "application")
            
            // Example to initialise AMVKit with an identity stored in a property file
            //let identity: Identity = try ApplicationPropertiesReader.createProperties(fromPropertyList: "identity")
            //initialisedAMVKit(AccessSdkOptions(accessApiContext, identity))
            
            initialisedAMVKit(AccessSdkOptions(accessApiContext))
        }
        catch {
            displayErrorText("Error while loading application properties", error: error)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let controller = segue.destination as? ControlViewController else {
            return
        }

        guard let cell = sender as? UITableViewCell else {
            return
        }

        guard let index = tableView.indexPath(for: cell)?.row else {
            return
        }

        controller.accessCertificate = accessCertificates[index]
    }
}

private extension TableViewController {

    func addAccessCertificates(_ accessCertificates: [AmvAccessCertificate]) {
        let indexPaths = (0..<accessCertificates.count).map { IndexPath(row: $0, section: 0) }

        self.accessCertificates = accessCertificates

        tableView.beginUpdates()
        tableView.insertRows(at: indexPaths, with: .automatic)
        tableView.endUpdates()
    }

    func clearAccessCertificates() {
        let indexPaths = (0..<accessCertificates.count).map { IndexPath(row: $0, section: 0) }

        accessCertificates.removeAll()

        tableView.beginUpdates()
        tableView.deleteRows(at: indexPaths, with: .automatic)
        tableView.endUpdates()
    }

    func initialisedAMVKit(_ accessSdkOptions: AccessSdkOptions) {
        do {
            try AMVKit.shared.initialise(accessSdkOptions: accessSdkOptions, handler: { result in
                OperationQueue.main.addOperation {
                    switch result {
                    case .error(let error):
                        self.displayErrorText("Device Certificate download failure", error: error)

                        self.refreshButton.isEnabled = true

                    case .success(let deviceCertificate):
                        if let serial = deviceCertificate.serial?.lowercased() {
                            print("Device serial:", serial)
                        }

                        self.loadAccessCertificates()
                        self.navigationItem.title = deviceCertificate.serial
                    }
                }
            })
        }
        catch {
            displayErrorText("AMVKit initialisation error", error: error)
        }
    }

    func loadAccessCertificates() {
        if let accessCertificates = AMVKit.shared.getAccessCertificates() {
            clearAccessCertificates()
            addAccessCertificates(accessCertificates)
            self.refreshButton.isEnabled = true
        }
        else {
            refreshAccessCertificates()
        }
    }

    func refreshAccessCertificates() {
        clearAccessCertificates()

        refreshButton.isEnabled = false

        do {
            try AMVKit.shared.refreshAccessCertificates {
                switch $0 {
                case .error(let error):
                    self.displayErrorText("Access Certificates download failure", error: error)
                    self.refreshButton.isEnabled = true

                case .success(let accessCertificates):
                    OperationQueue.main.addOperation {
                        self.addAccessCertificates(accessCertificates)
                        self.refreshButton.isEnabled = true
                    }
                }
            }
        }
        catch {
            displayErrorText("Access Certificates download error", error: error)
            refreshButton.isEnabled = true
        }
    }

    func refreshCell(at indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
}
