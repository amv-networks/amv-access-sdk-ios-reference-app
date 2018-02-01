import AMVKit
import UIKit


class ControlViewController: UIViewController {

    @IBOutlet var infoContainer: UIView!

    @IBOutlet var chargingPlugSwitch: UISwitch!
    @IBOutlet var doorsSwitch: UISwitch!
    @IBOutlet var keySwitch: UISwitch!
    @IBOutlet var mileageLabel: UILabel!

    @IBOutlet var lockButton: UIButton!
    @IBOutlet var unlockButton: UIButton!


    // MARK: Vars

    var accessCertificate: AccessCertificate!


    // MARK: IBActions

    @IBAction func lockButtonTapped(_ sender: UIButton) {
        enableButtons(false)

        do {
            try AMVKit.shared.sendCommand(.lockDoors)
        }
        catch {
            displayErrorText("Lock Doors failure", error: error)
        }
    }

    @IBAction func unlockButtonTapped(_ sender: UIButton) {
        enableButtons(false)

        do {
            try AMVKit.shared.sendCommand(.unlockDoors)
        }
        catch {
            displayErrorText("Unlock Doors failure", error: error)
        }
    }


    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide the views at first a bit
        infoContainer.alpha = 0.5
        lockButton.isHidden = true
        unlockButton.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Connect automatically
        do {
            try AMVKit.shared.connect(to: accessCertificate) {
                switch $0 {
                case .error(let error):
                    self.displayErrorText("Connection error", error: error)

                case .success(let update):
                    self.updateReceived(update)
                }
            }
        }
        catch {
            displayErrorText("Connection failure", error: error)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        AMVKit.shared.disconnect()
    }
}

private extension ControlViewController {

    func enableButtons(_ enable: Bool) {
        // Even though 1 button is hidden, it's easier to change them like so
        lockButton.isEnabled = enable
        unlockButton.isEnabled = enable

        lockButton.alpha = enable ? 1.0 : 0.5
        unlockButton.alpha = enable ? 1.0 : 0.5
    }


    // MARK: Update

    func chargingReceived(_ update: Charging) {
        chargingPlugSwitch.isOn = update.isPlugConnected
    }

    func connectionStatusReceived(_ status: ConnectionStatus) {
        switch status {
        case .authenticated:
            navigationItem.title = "Authenticated - " + accessCertificate.name

        case .connected:
            navigationItem.title = "Connected - " + accessCertificate.name

        case .disconnected:
            navigationItem.title = "Disconnected - " + accessCertificate.name
        }
    }

    func diagnosticsReceived(_ update: Diagnostics) {
        mileageLabel.text = "\(update.mileage) km"
    }

    func doorsReceived(_ update: Doors) {
        lockButton.isHidden = update.isLocked
        unlockButton.isHidden = !update.isLocked

        doorsSwitch.isOn = !update.isOpen

        enableButtons(true)
    }

    func keysReceived(_ update: Keys) {
        keySwitch.isOn = update.isInside
    }

    func updateReceived(_ update: VehicleUpdate) {
        OperationQueue.main.addOperation {
            if !(update is ConnectionStatus) {
                self.infoContainer.alpha = 1.0
            }

            // Forward the updates
            switch update {
            case let charging as Charging:
                self.chargingReceived(charging)

            case let connectionStatus as ConnectionStatus:
                self.connectionStatusReceived(connectionStatus)

            case let diagnostics as Diagnostics:
                self.diagnosticsReceived(diagnostics)

            case let doors as Doors:
                self.doorsReceived(doors)

            case let keys as Keys:
                self.keysReceived(keys)

            default:
                print("Unknown vehicle state received")
                break;
            }
        }
    }
}
