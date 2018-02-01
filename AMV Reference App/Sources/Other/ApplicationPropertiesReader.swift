import Foundation

public class ApplicationPropertiesReader {
    public static func createProperties<T: Decodable>(fromPropertyList fileName: String) throws -> T {
        guard let applicationSettingsDictionary = Bundle.main.path(forResource: fileName, ofType: "plist") else {
            throw Failure.missingApplicationProperties
        }
        
        do {
            let url = URL(fileURLWithPath: applicationSettingsDictionary)
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            
            return try decoder.decode(T.self, from: data)
        } catch {
            print(error)
            throw error
        }
    }
}
