//
//  FormIconFetchLocal.swift
//  Form
//


import Foundation
import FetchOperation
import ServerDTO
import Persistence
import ZipArchive
import Pipeline

public struct FormLocalSaveResult: Sendable {
    var zipsUnzipped: Int
}

final class FormIconFetchLocal: FetchLocalDataSource {
    typealias DTO = URL
    
    let eventID: EventID
    init(eventID: EventID) {
        self.eventID = eventID
    }
    
    func save(_ dto: [URL], progress: @escaping OperationProgressHandler) async throws -> FormLocalSaveResult {
        NSLog("event form icon request complete for event \(eventID.rawValue)")
        let folderToUnzipTo = "\(getDocumentsDirectory())/events/icons-\(eventID.rawValue)"
        
        guard let fileUrl = dto.first else {
            return FormLocalSaveResult(zipsUnzipped: 0)
        }
        
        let fileString = fileUrl.path
        
        if !FileManager.default.fileExists(atPath: folderToUnzipTo) {
            do {
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: folderToUnzipTo).deletingLastPathComponent(), withIntermediateDirectories: true)
            } catch {
                NSLog("Error creating directory for icons \(error)")
            }
        }
        
        try SSZipArchive.unzipFile(atPath: fileString, toDestination: folderToUnzipTo, overwrite: true,password:nil)
        if FileManager.default.isDeletableFile(atPath: fileString) {
            do {
                try FileManager.default.removeItem(atPath: fileString)
            } catch {
                NSLog("Error removing file at path: %@", error.localizedDescription);
            }
        }
        
        return FormLocalSaveResult(zipsUnzipped: 1)
    }
    
    func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as String
    }
    
}
