@testable import AMVKit

import XCTest


class AccessCertificateTests: XCTestCase {

    private var serial: Hex?
    private var accessSdkOptions: AccessSdkOptions?

    // MARK: Management

    override func setUp() {
        super.setUp()

        AMVKit.shared.logRequestsResponse = true

        do {
            let accessApiContext: AccessApiContext = try ApplicationPropertiesReader.createProperties(fromPropertyList: "application")
            self.accessSdkOptions = AccessSdkOptions(accessApiContext)

            let serialExpectation = expectation(description: "Downloaded device certificate's serial")

            try DeviceCertificate.download(publicKey: KeysManager.shared.publicKey, accessSdkOptions: self.accessSdkOptions!) {
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

            try AccessCertificates.download(deviceSerial: serial, accessApiContext: self.accessSdkOptions!.accessApiContext) {
                switch $0 {
                case .error(let error):
                    XCTFail("Download failed, error: \(error)")

                case .success(let accessCertificates):
                    if let pair = accessCertificates.all.first {
                        // Check that the Access Certificate meant for the device has a correct serial number
                        XCTAssertEqual(pair.deviceCertificate.providingSerial.hex, serial, "Wrong serial number in device Access Certificate")
                        
                        // save the previous downloaded acccess certificate
                        // findAcessCertificateById loads them from local storage
                        accessCertificates.save()
                        self.findAcessCertificateById(accessCertificateToTest: pair)
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
    
    func findAcessCertificateById(accessCertificateToTest accessCertificate: AccessCertificate) {
        let identifier = accessCertificate.identifier

        // previous stored certificate
        XCTAssertTrue(AMVKit.shared.getAccessCertificateById(identifier) == accessCertificate)
        
        // random identifier
        XCTAssertNil(AMVKit.shared.getAccessCertificateById(UUID().uuidString))
    }
}
