@testable import AMVKit

import XCTest

class IndentityTests: XCTestCase {
    func test_findIdentityShouldReturnPreviousStoredIdentity() {
        
        do {
            let initialiseExpectation = expectation(description: "Initialise expectation")
            
            let accessApiContext: AccessApiContext = try ApplicationPropertiesReader.createProperties(fromPropertyList: "application")
            let initialisedIdentity: Identity = try ApplicationPropertiesReader.createProperties(fromPropertyList: "identity")
            
            try AMVKit.shared.initialise(accessSdkOptions: AccessSdkOptions(accessApiContext, initialisedIdentity), handler: { result in
                    switch result {
                        case .error(let error):
                            XCTFail("Failed to initialise AMVKit, error: \(error)")
                        case .success(let deviceCertificate):
                            if let serial = deviceCertificate.serial?.lowercased() {
                                XCTAssertEqual(serial, initialisedIdentity.deviceSerialNumber)
                                
                                let identity = IdentityManager.findIdentity()
                                
                                XCTAssertNotNil(identity)
                                XCTAssertEqual(initialisedIdentity, identity!)
                            }
                    }
                
                    initialiseExpectation.fulfill()
                }
            )
            
            waitForExpectations(timeout: 30.0)
        } catch {
            XCTFail("Failed to start downloading Device Certificate, error: \(error)")
        }
    }
    
}
