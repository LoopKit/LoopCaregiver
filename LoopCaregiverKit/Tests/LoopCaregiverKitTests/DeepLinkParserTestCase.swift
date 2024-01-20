//
//  DeepLinkParserTestCase.swift
//  LoopCaregiverTests
//
//  Created by Bill Gestrich on 10/18/23.
//

@testable import LoopCaregiverKit
import XCTest

final class DeepLinkParserTestCase: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
    
    func testParsingURL_WithUknownAction_Throws() throws {
        
        //Arrange
        let parser = DeepLinkParser()
        let url = URL(string: "caregiver://unknown")!
        var errorResult: Error? = nil
        
        //Act
        do {
            let _ = try parser.parseDeepLink(url: url)
        } catch {
            errorResult = error
        }
        
        //Assert
        guard let unknownActionError = errorResult as? DeepLinkParser.DeepLinkError else {
            XCTFail("Unexpected failure type")
            return
        }
        
        XCTAssertEqual(unknownActionError.localizedDescription, "Unknown Action: unknown")
    }
    
    
    //MARK: Select Looper

    func testSelectLooper_WithValidURL_IsValid() throws {
        
        //Arrange
        let parser = DeepLinkParser()
        let url = URL(string: "caregiver://selectLooper/12345")!
        
        //Act
        let result = try parser.parseDeepLink(url: url)
        
        //Assert
        if case .selectLooper(let deepLink) = result {
            XCTAssertEqual(deepLink.looperUUID, "12345")
        } else {
            XCTFail("Unexpected parse result")
        }
    }

    func testSelectLooper_MissingUUID_Throws() throws {
        
        //Arrange
        let parser = DeepLinkParser()
        let url = URL(string: "caregiver://selectLooper")!
        var errorResult: Error? = nil
        
        //Act
        do {
            let _ = try parser.parseDeepLink(url: url)
        } catch {
            errorResult = error
        }
        
        //Assert
        guard let selectedLoopError = errorResult as? SelectLooperDeepLink.SelectLooperDeepLinkError else {
            XCTFail("Unexpected failure type")
            return
        }
        XCTAssertEqual(selectedLoopError.localizedDescription, "This widget requires configuration.")
    }
    
    func testSelectLooperURLFormation_IsSuccessful() throws {
        
        //Arrange
        let deepLink = SelectLooperDeepLink(looperUUID: "12345")
        
        //Act
        let url = deepLink.toURL()
        
        //Assert
        XCTAssertEqual(url, "caregiver://selectLooper/12345")
    }
    
    
    //MARK: Add Looper
    
    //caregiver://createLooper?name=Joe&secretKey=ABCDEFGHIJ&nsURL=https://example.com&otpURL=otpauth://totp/1651507264639?algorithm=SHA1&digits=6&issuer=Loop&period=30&secret=5WUYBVFE7XVTOFOMBQMDTBJP7JHBWOW3
    
    //caregiver://createLooper?name=Joe&secretKey=ABCDEFGHIJ&nsURL=https%3A%2F%2Fexample.com&otpURL=otpauth%3A%2F%2Ftotp%2F1651507264639%3Falgorithm%3DSHA1%26digits%3D6%26issuer%3DLoop%26period%3D30%26secret%3D5WUYBVFE7XVTOFOMBQMDTBJP7JHBWOW3
    
    func testAddLooper_WithValidURL_IsValid() throws {
        
        //Arrange
        let parser = DeepLinkParser()
        let url = URL(string: "caregiver://createLooper?name=Joe&secretKey=ABCDEFGHIJ&nsURL=https%3A%2F%2Fexample.com&otpURL=otpauth%3A%2F%2Ftotp%2F1651507264639%3Falgorithm%3DSHA1%26digits%3D6%26issuer%3DLoop%26period%3D30%26secret%3D5WUYBVFE7XVTOFOMBQMDTBJP7JHBWOW3")!
        
        //Act
        let result = try parser.parseDeepLink(url: url)
        
        //Assert
        if case .addLooper(let deepLink) = result {
            XCTAssertEqual(deepLink.name, "Joe")
            XCTAssertEqual(deepLink.nsURL, URL(string: "https://example.com"))
            XCTAssertEqual(deepLink.secretKey, "ABCDEFGHIJ")
            XCTAssertEqual(deepLink.otpURL, URL(string: "otpauth://totp/1651507264639?algorithm=SHA1&digits=6&issuer=Loop&period=30&secret=5WUYBVFE7XVTOFOMBQMDTBJP7JHBWOW3"))
            XCTAssertEqual(deepLink.secretKey, "ABCDEFGHIJ")
        } else {
            XCTFail("Unexpected parse result")
        }
    }
    
    func testAddLooper_MissingName_Fails() throws {
        
        //Arrange
        let parser = DeepLinkParser()
        let url = URL(string: "caregiver://createLooper?secretKey=ABCDEFGHIJ&nsURL=https%3A%2F%2Fexample.com&otpURL=otpauth%3A%2F%2Ftotp%2F1651507264639%3Falgorithm%3DSHA1%26digits%3D6%26issuer%3DLoop%26period%3D30%26secret%3D5WUYBVFE7XVTOFOMBQMDTBJP7JHBWOW3")!
        
        //Act
        var errorResult: Error?
        do {
            let _ = try parser.parseDeepLink(url: url)
        } catch {
            errorResult = error
        }
        
        //Assert
        guard let createLooperError = errorResult as? CreateLooperDeepLink.CreateLooperDeepLinkError else {
            XCTFail("Unexpected failure type")
            return
        }
        XCTAssertEqual(createLooperError, CreateLooperDeepLink.CreateLooperDeepLinkError.missingName)
    }
    
    
    func testAddLooper_MissingSecretKey_Fails() throws {
        
        //Arrange
        let parser = DeepLinkParser()
        let url = URL(string: "caregiver://createLooper?name=Joe&nsURL=https%3A%2F%2Fexample.com&otpURL=otpauth%3A%2F%2Ftotp%2F1651507264639%3Falgorithm%3DSHA1%26digits%3D6%26issuer%3DLoop%26period%3D30%26secret%3D5WUYBVFE7XVTOFOMBQMDTBJP7JHBWOW3")!
        
        //Act
        var errorResult: Error?
        do {
            let _ = try parser.parseDeepLink(url: url)
        } catch {
            errorResult = error
        }
        
        //Assert
        guard let createLooperError = errorResult as? CreateLooperDeepLink.CreateLooperDeepLinkError else {
            XCTFail("Unexpected failure type")
            return
        }
        XCTAssertEqual(createLooperError, CreateLooperDeepLink.CreateLooperDeepLinkError.missingNSSecretKey)
    }
    
    func testAddLooper_MissingNSURL_Fails() throws {
        
        //Arrange
        let parser = DeepLinkParser()
        let url = URL(string: "caregiver://createLooper?name=Joe&secretKey=ABCDEFGHIJ&otpURL=otpauth%3A%2F%2Ftotp%2F1651507264639%3Falgorithm%3DSHA1%26digits%3D6%26issuer%3DLoop%26period%3D30%26secret%3D5WUYBVFE7XVTOFOMBQMDTBJP7JHBWOW3")!
        
        //Act
        var errorResult: Error?
        do {
            let _ = try parser.parseDeepLink(url: url)
        } catch {
            errorResult = error
        }
        
        //Assert
        guard let createLooperError = errorResult as? CreateLooperDeepLink.CreateLooperDeepLinkError else {
            XCTFail("Unexpected failure type")
            return
        }
        XCTAssertEqual(createLooperError, CreateLooperDeepLink.CreateLooperDeepLinkError.missingNSURL)
    }
    
    func testAddLooper_MissingOTPURL_Fails() throws {
        
        //Arrange
        let parser = DeepLinkParser()
        let url = URL(string: "caregiver://createLooper?name=Joe&secretKey=ABCDEFGHIJ&nsURL=https%3A%2F%2Fexample.com")!
        
        //Act
        var errorResult: Error?
        do {
            let _ = try parser.parseDeepLink(url: url)
        } catch {
            errorResult = error
        }
        
        //Assert
        guard let createLooperError = errorResult as? CreateLooperDeepLink.CreateLooperDeepLinkError else {
            XCTFail("Unexpected failure type")
            return
        }
        XCTAssertEqual(createLooperError, CreateLooperDeepLink.CreateLooperDeepLinkError.missingOTPURL)
    }

}
