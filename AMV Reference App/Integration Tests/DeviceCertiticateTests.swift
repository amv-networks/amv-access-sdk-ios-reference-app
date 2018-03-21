@testable import AMVKit

import XCTest


class DeviceCertiticateTests: XCTestCase {

    func test() {
        AMVKit.shared.logRequestsResponse = true

        do {
            let downloadExpectation = expectation(description: "Downloaded valid Device Certificate")
            
            let accessApiContext: AccessApiContext = try ApplicationPropertiesReader.createProperties(fromPropertyList: "application")
            let accessSdkOptions = AccessSdkOptions(accessApiContext)

            try DeviceCertificate.download(publicKey: KeysManager.shared.publicKey, accessSdkOptions: accessSdkOptions) {
                switch $0 {
                case .error(let error):
                    XCTFail("Download failed, error: \(error)")

                case .success(let deviceCertificate):
                    // Serial size is 9 bytes - that's 18 characters in hex
                    XCTAssertEqual(deviceCertificate.serial?.count, 18, "Serial size is wrong.")

                    // Public key size is 64 bytes
                    XCTAssertEqual(Data(base64Encoded: deviceCertificate.issuerPublicKey)?.count, 64, "Issuer public key size is wrong.")
                }

                downloadExpectation.fulfill()
            }

            waitForExpectations(timeout: 30.0)
        }
        catch {
            XCTFail("Failed to start downloading Device Certificate, error: \(error)")
        }
    }
}
