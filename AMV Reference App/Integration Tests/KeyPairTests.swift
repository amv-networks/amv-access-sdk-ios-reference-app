@testable import AMVKit

import XCTest


class KeyPairTests: XCTestCase {
    
    func test() {
        let privateKey = KeysManager.shared.privateKey
        let publicKey = KeysManager.shared.publicKey

        XCTAssertEqual(privateKey.count, 32, "Private key size is wrong.")
        XCTAssertEqual(publicKey.count, 64, "Public key size is wrong.")
    }
}
