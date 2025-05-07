import XCTest
import CoreData
@testable import PhotoEase

final class PhotoEaseTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

// MARK: - Model Photo Tests
extension PhotoEaseTests {
    
    // Test photo creation by JSON Decoding
    // It happens when calling an API to get list of photos from the internet
    func testPhotoSuccessulCreationByJSONDecoding() {
        // Given data
        let json = """
            {
                "albumId": 1,
                "id": 1,
                "title": "Photo Title",
                "url": "https://dummyimage.com/700/92c952",
                "thumbnailUrl": "https://dummyimage.com/200/92c952"
            }
            """.data(using: .utf8)!

        let photo = try! JSONDecoder().decode(Photo.self, from: json)
        
        XCTAssertEqual(photo.albumId, 1)
        XCTAssertEqual(photo.id, 1)
        XCTAssertEqual(photo.title, "Photo Title")
        XCTAssertEqual(photo.url?.absoluteString, "https://dummyimage.com/700/92c952")
        XCTAssertEqual(photo.thumbnailUrl?.absoluteString, "https://dummyimage.com/200/92c952")
    }
    
    // Test photo creation from a managed photo
    // It happens when converting a managed photo from Core Data to a photo object to display on the UI
    func testPhotoSuccessfulCreationFromAManagedPhoto() {
        let context = PhotoDataHelper.shared.persistentContainer.viewContext
        let managedPhoto = ManagedPhoto(context: context)
        managedPhoto.albumId = 1
        managedPhoto.id = 1
        managedPhoto.title = "Photo Title"
        managedPhoto.url = "https://dummyimage.com/700/92c952"
        managedPhoto.thumbnailUrl = "https://dummyimage.com/200/92c952"
        
        let photo = Photo(fromManagedPhoto: managedPhoto)
        XCTAssertEqual(photo.albumId, 1)
        XCTAssertEqual(photo.id, 1)
        XCTAssertEqual(photo.title, "Photo Title")
        XCTAssertEqual(photo.url?.absoluteString, "https://dummyimage.com/700/92c952")
        XCTAssertEqual(photo.thumbnailUrl?.absoluteString, "https://dummyimage.com/200/92c952")
    }
    
    // Test to make sure URL is converted from 'via.placeholder.com' to 'dummyimage.com'
    func testPhotoURLReplacement() {
        let json = """
            {
                "albumId": 1,
                "id": 1,
                "title": "Photo Title",
                "url": "https://via.placeholder.com/700/92c952",
                "thumbnailUrl": "https://via.placeholder.com/200/92c952"
            }
            """.data(using: .utf8)!

        let photo = try! JSONDecoder().decode(Photo.self, from: json)

        // Check if URLs are replaced correctly
        XCTAssertEqual(photo.url?.absoluteString, "https://dummyimage.com/700/92c952", "Photo URL should be replaced with dummyimage.com")
        XCTAssertEqual(photo.thumbnailUrl?.absoluteString, "https://dummyimage.com/200/92c952", "Thumbnail URL should be replaced with dummyimage.com")
    }
    
    // Test photo creation by JSON Decoding with missing URL fields
    func testPhotoCreationWithMissingFields() {
        // JSON data without `url` and `thumbnailUrl`
        let json = """
            {
                "albumId": 1,
                "id": 1,
                "title": "Photo Title"
            }
            """.data(using: .utf8)!

        do {
            let photo = try JSONDecoder().decode(Photo.self, from: json)
            XCTAssertEqual(photo.albumId, 1)
            XCTAssertEqual(photo.id, 1)
            XCTAssertEqual(photo.title, "Photo Title")
            XCTAssertNil(photo.url, "URL should be nil when not provided in the JSON")
            XCTAssertNil(photo.thumbnailUrl, "Thumbnail URL should be nil when not provided in the JSON")
        } catch {
            XCTFail("Decoding shouldn't fail")
        }
    }
    
    // Test the decoding of the photo object when provided with invalid URL strings
    func testPhotoCreationWithInvalidURLs() {
        let json = """
            {
                "albumId": 1,
                "id": 1,
                "title": "Photo Title",
                "url": "htp://invalid-url",
                "thumbnailUrl": "htps://invalid-url"
            }
            """.data(using: .utf8)!

        let photo = try? JSONDecoder().decode(Photo.self, from: json)
        XCTAssertNil(photo?.url, "URL should be nil when provided with an invalid format")
        XCTAssertNil(photo?.thumbnailUrl, "Thumbnail URL should be nil when provided with an invalid format")
    }
    
    // Test the decoding of the photo object when URL fields are null in the JSON
    func testPhotoCreationWithNullURLs() {
        let json = """
            {
                "albumId": 1,
                "id": 1,
                "title": "Photo Title",
                "url": null,
                "thumbnailUrl": null
            }
            """.data(using: .utf8)!

        do {
            let photo = try JSONDecoder().decode(Photo.self, from: json)
            XCTAssertEqual(photo.albumId, 1)
            XCTAssertEqual(photo.id, 1)
            XCTAssertEqual(photo.title, "Photo Title")
            XCTAssertNil(photo.url, "URL should be nil if JSON contains a null value for it")
            XCTAssertNil(photo.thumbnailUrl, "Thumbnail URL should be nil if JSON contains a null value for it")
        } catch {
            XCTFail("Decoding should not fail even when URLs are null: \(error)")
        }
    }
    
    // Test for missing or incorrect data type for `albumId`, `id`, and `title` in the JSON data
    func testPhotoValidationWithIncorrectOrMissingFields() {
        let jsonWithMissingFields = """
            {
                "title": "Photo Title",
                "url": "https://dummyimage.com/700/92c952",
                "thumbnailUrl": "https://dummyimage.com/200/92c952"
            }
            """.data(using: .utf8)!

        let jsonWithIncorrectDataTypes = """
            {
                "albumId": "A string value",
                "id": "A string value",
                "title": 100
            }
            """.data(using: .utf8)!

        // Test for missing fields
        do {
            let _ = try JSONDecoder().decode(Photo.self, from: jsonWithMissingFields)
            XCTFail("Decoding should fail when required fields are missing")
        } catch {
            // Expected failure
        }

        // Test for incorrect types
        do {
            let _ = try JSONDecoder().decode(Photo.self, from: jsonWithIncorrectDataTypes)
            XCTFail("Decoding should fail when fields are of incorrect type")
        } catch {
            // Expected failure
        }
    }
}
