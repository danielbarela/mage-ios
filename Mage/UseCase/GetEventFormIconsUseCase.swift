// 
//     
//  GetEventFormIconsUseCase.swift
//  MAGE
//
// 


import Foundation
import Form
import FetchOperation
import UseCaseFactory
import ServerDTO

public final class GetEventFormIconsUseCase: Sendable, UseCase {
    let formIconFetch: AnyFetchRepository<FormIconFetchRequest, [URL]>
    
    init(formIconFetch: AnyFetchRepository<FormIconFetchRequest, [URL]>) {
        self.formIconFetch = formIconFetch
    }
    
    func execute(eventID: EventID) async throws {
        let operation = formIconFetch.startFetch(FormIconFetchRequest(eventID: eventID))
        let output = try await operation.value()
        FormPackage.logger.info("Fetched Form Icons \(output.count) zip")
        NotificationCenter.default.post(name: .MAGEFormFetched, object: eventID)
    }
}
