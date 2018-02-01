@testable import AMVKit

import XCTest


class AccessCertificateTests: XCTestCase {

    private var serial: Hex?
    private var accessApiContext: AccessApiContext?

    // MARK: Management

    override func setUp() {
        super.setUp()

        AMVKit.shared.logRequestsResponse = true

        do {
            self.accessApiContext = try ApplicationPropertiesReader.createProperties(fromPropertyList: "application")
            
            let serialExpectation = expectation(description: "Downloaded device certificate's serial")

            try DeviceCertificate.download(publicKey: KeysManager.shared.publicKey, accessApiContext: self.accessApiContext!) {
                if case .success(let deviceCertificate) = $0 {
                    self.serial = deviceCertificate.serial
                }

                serialExpectation.fulfill()
            }

            waitForExpectations(timeout: 30.0)
        }
        catch {
            XCTFail("Failed to start downloading Device Certificate, error: \(error)")
        }
    }

    override func tearDown() {
        super.tearDown()

        serial = nil
    }


    // MARK: Tests
    func testDownload() {
        guard let serial = serial else {
            return XCTFail("Missing device serial")
        }

        do {
            let downloadExpectation = expectation(description: "Downloaded valid Access Certificates")

            try AccessCertificates.download(deviceSerial: serial, accessApiContext: self.accessApiContext!) {
                switch $0 {
                case .error(let error):
                    XCTFail("Download failed, error: \(error)")

                case .success(let accessCertificates):
                    if let pair = accessCertificates.all.first {
                        // Check that the Access Certificate meant for the device has a correct serial number
                        XCTAssertEqual(pair.deviceCertificate.providingSerial.hex, serial, "Wrong serial number in device Access Certificate")
                    }
                    else {
                        XCTFail("Access Certificates response does not contain any.")
                    }
                }

                downloadExpectation.fulfill()
            }

            waitForExpectations(timeout: 30.0)
        }
        catch {
            XCTFail("Failed to start downloading Access Certificates, error: \(error)")
        }
    }
}