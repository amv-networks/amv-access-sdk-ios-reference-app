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

    var accessCertificate: AmvAccessCertificate!
    var firstCall = true


    // MARK: IBActions

    @IBAction func lockButtonTapped(_ sender: UIButton) {
        lockDoors()
    }

    @IBAction func unlockButtonTapped(_ sender: UIButton) {
        unlockDoors()
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
    
        self.firstCall = true

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

    func chargingReceived(_ update: AMVCharging) {
        chargingPlugSwitch.isOn = update.isPlugConnected
    }

    func connectionStatusReceived(_ status: AMVConnectionStatus) {
        switch status {
        case .authenticated:
            navigationItem.title = "Authenticated - " + accessCertificate.name
            
            DispatchQueue.main.async {
                do {
                    try AMVKit.shared.sendCommand(.requestVehicleState)
                }
                catch {
                    self.displayErrorText("Request Vehicle State failure", error: error)
                }
            }

        case .connected:
            navigationItem.title = "Connected - " + accessCertificate.name

        case .disconnected:
            navigationItem.title = "Disconnected - " + accessCertificate.name
        }
    }

    func diagnosticsReceived(_ update: AMVDiagnostics) {
        mileageLabel.text = "\(update.mileage) km"
    }

    func doorsReceived(_ update: AMVDoors) {
        lockButton.isHidden = update.isLocked
        unlockButton.isHidden = !update.isLocked

        doorsSwitch.isOn = !update.isOpen

        enableButtons(true)
    }

    func keysReceived(_ update: AMVKeys) {
        keySwitch.isOn = update.isInside
    }

    func updateReceived(_ update: VehicleUpdate) {
        OperationQueue.main.addOperation {
            if !(update is AMVConnectionStatus) {
                self.infoContainer.alpha = 1.0
            }

            // Forward the updates
            switch update {
            case let charging as AMVCharging:
                self.chargingReceived(charging)

            case let connectionStatus as AMVConnectionStatus:
                self.connectionStatusReceived(connectionStatus)

            case let diagnostics as AMVDiagnostics:
                self.diagnosticsReceived(diagnostics)

            case let doors as AMVDoors:
                self.doorsReceived(doors)
                
                if self.firstCall {
                    self.firstCall = false
                    
                    DispatchQueue.main.async {
                        self.lockUnlockDoors(doorsState: doors)
                    }
                }

            case let keys as AMVKeys:
                self.keysReceived(keys)

            default:
                print("Unknown vehicle state received")
                break;
            }
        }
    }
    
    func lockUnlockDoors(doorsState: AMVDoors) {
        if doorsState.isLocked {
            unlockDoors()
        } else {
            lockDoors()
        }
    }
    
    func lockDoors() {
        enableButtons(false)
        
        do {
            try AMVKit.shared.sendCommand(.lockDoors)
        }
        catch {
            displayErrorText("Lock Doors failure", error: error)
        }
    }
    
    func unlockDoors() {
        enableButtons(false)
        
        do {
            try AMVKit.shared.sendCommand(.unlockDoors)
        }
        catch {
            displayErrorText("Unlock Doors failure", error: error)
        }
    }
}
