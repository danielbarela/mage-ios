//
//  FormIconFetchRemote.swift
//  Form
//


import Foundation
import APIRouter
import FetchOperation
import ServerDTO
import Alamofire
import Pipeline

final class FormIconFetchRemote: FetchRemoteDataSource {
    
    typealias DTO = URL
    
    let url: URL
    let session: TokenAPISession
    let eventID: EventID
    
    init(
        url: URL,
        session: TokenAPISession,
        eventID: EventID
    ) {
        self.url = url
        self.session = session
        self.eventID = eventID
    }
    
    func fetch(
        urlRequest: URLRequest? = nil,
        progress: @escaping OperationProgressHandler
    ) async throws -> [URL] {
        
        let request = FormRouter(
            baseURL: url,
            endpoint: .fetchIcons(eventId: eventID.rawValue)
        )
        
        let destination: DownloadRequest.Destination = {
             temporaryURL,
             response in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appending(
                components: "events",
                "icons-\(self.eventID.rawValue).zip"
            )
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        do {
            
            let fileURL = try await session.session
                .download(request, to: destination)
                .downloadProgress { download in
                    progress(
                        OperationProgress(
                            completed: download.completedUnitCount,
                            total: download.totalUnitCount
                        )
                    )
                }
                .validate(session.validateDownloadResponse())
                .serializingDownloadedFileURL()
                .value
            return [fileURL]
        } catch {
            throw error.asAFError?.underlyingError ?? error
        }
    }
}
