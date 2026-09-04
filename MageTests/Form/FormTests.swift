//
//  FormTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/15/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import OHHTTPStubs
import Persistence
import Form
import ServerDTO

@testable import MAGE

class FormTests: KIFSpec {
    
    override func spec() {
        
        describe("Form Tests") {
            
            beforeEach {
                TestHelpers.resetUserDefaults();
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.serverMajorVersion = 6;
                UserDefaults.standard.serverMinorVersion = 0;
            }
            
            afterEach {
                TestHelpers.resetUserDefaults();
            }
            
            func getDocumentsDirectory() -> String {
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsDirectory = paths[0]
                return documentsDirectory as String
            }
            
            it("should pull the forms for an event") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/form/icons.zip")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    let stubPath = OHPathForFile("plantsAnimalsBuildingsIcons.zip", FormTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/zip"]);
                }
                
                let stringPath = "\(getDocumentsDirectory())/events/icons-1.zip"
                let folderToUnzipTo = "\(getDocumentsDirectory())/events/icons-1"
                do {
                    try FileManager.default.removeItem(atPath: folderToUnzipTo)
                } catch {
                    NSLog("Error removing file at path: %@", error.localizedDescription);
                }
                expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beFalse());

                
                var formPullSuccessCalled = false;
                let useCase = GetEventFormIconsUseCase(
                    formIconFetch: FormRepositoryFactory
                        .createFormIconFetchRepository(
                            url: URL(string: "https://magetest")!,
                            session: TokenAPISessionImpl(baseURL: URL(string: "https://magetest")!, loginType: "online")
                        )
                )
                Task {
                    do {
                        try await useCase.execute(eventID: EventID(1))
                        formPullSuccessCalled = true
                    } catch { }
                }
                
                expect(stubCalled).toEventually(beTrue());
                expect(formPullSuccessCalled).toEventually(beTrue());
                
                expect(FileManager.default.fileExists(atPath: stringPath)).to(beFalse());
                expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beTrue());
            }
            
            it("should fail when the icons.zip is not a zip") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/form/icons.zip")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    let stubPath = OHPathForFile("icon27.png", FormTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/zip"]);
                }
                
                let stringPath = "\(getDocumentsDirectory())/events/icons-1.zip"
                let folderToUnzipTo = "\(getDocumentsDirectory())/events/icons-1"
                do {
                    try FileManager.default.removeItem(atPath: folderToUnzipTo)
                } catch {
                    NSLog("Error removing file at path: %@", error.localizedDescription);
                }
                expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beFalse());
                
                
                var formPullFailureCalled = false;
                let useCase = GetEventFormIconsUseCase(
                    formIconFetch: FormRepositoryFactory
                        .createFormIconFetchRepository(
                            url: URL(string: "https://magetest")!,
                            session: TokenAPISessionImpl(baseURL: URL(string: "https://magetest")!, loginType: "online")
                        )
                )
                Task {
                    do {
                        try await useCase.execute(eventID: EventID(1))
                    } catch {
                        formPullFailureCalled = true
                    }
                }
                
                expect(stubCalled).toEventually(beTrue());
                expect(formPullFailureCalled).toEventually(beTrue());
                
                expect(FileManager.default.fileExists(atPath: stringPath)).to(beFalse());
                expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beFalse());
            }
            
            it("should fail when the server returns an error") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/form/icons.zip")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    return HTTPStubsResponse(error: NSError(domain: "bad", code: 503, userInfo: nil))
                }
                
                let stringPath = "\(getDocumentsDirectory())/events/icons-1.zip"
                let folderToUnzipTo = "\(getDocumentsDirectory())/events/icons-1"
                do {
                    try FileManager.default.removeItem(atPath: folderToUnzipTo)
                } catch {
                    NSLog("Error removing file at path: %@", error.localizedDescription);
                }
                expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beFalse());
                
                
                var formPullFailureCalled = false;
                let useCase = GetEventFormIconsUseCase(
                    formIconFetch: FormRepositoryFactory
                        .createFormIconFetchRepository(
                            url: URL(string: "https://magetest")!,
                            session: TokenAPISessionImpl(baseURL: URL(string: "https://magetest")!, loginType: "online")
                        )
                )
                Task {
                    do {
                        try await useCase.execute(eventID: EventID(1))
                    } catch {
                        formPullFailureCalled = true
                    }
                }
                
                expect(stubCalled).toEventually(beTrue());
                expect(formPullFailureCalled).toEventually(beTrue());
                
                expect(FileManager.default.fileExists(atPath: stringPath)).to(beFalse());
                expect(FileManager.default.fileExists(atPath: folderToUnzipTo)).to(beFalse());
            }
        }
        
    }
    
}
