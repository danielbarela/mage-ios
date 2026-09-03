//
//  FormLocalDataSourceTests.swift
//  Form
//
//  Created by Daniel Barela on 1/9/26.
//

import Foundation
import Testing
import Persistence
import CoreData
import ServerDTO

@testable import TestUtilities
@testable import Form

@MainActor

struct FormLocalDataSourceTests {
    
    @Test
    func `handle form zip`() async throws {
        let localDataSource = FormIconFetchLocal(eventID: EventID(1))
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsDirectory
            .appendingPathComponent("events")
            .appendingPathComponent("icons-1")
        
        try? FileManager.default.removeItem(at: url)
        
        
        let zipUrl = TestUtilities.urlForFile("plantsAnimalsBuildingsIcons", withExtension: "zip")
        
        let copyToPath = documentsDirectory.appendingPathComponent("plantsAnimalsBuildingsIcons.zip")
        do {
            try FileManager.default.copyItem(at: zipUrl!, to: copyToPath);
        } catch {
            print("Error", error);
        }
        
        let unzipped = try await localDataSource.save([copyToPath]) { progress in
            
        }
        
        #expect(unzipped.zipsUnzipped != 0)

        #expect(FileManager.default.fileExists(atPath: url.path()))
    }

}
