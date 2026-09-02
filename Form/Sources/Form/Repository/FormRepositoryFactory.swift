//
//  FormRepositoryFactory.swift
//  Form
//

import APIRouter
import Persistence
import Foundation
import FetchOperation
import ServerDTO
import Pipeline

public struct FormIconFetchRequest: Sendable {
    public let eventID: EventID
    
    public init(
        eventID: EventID
    ) {
        self.eventID = eventID
    }
}

public class FormRepositoryFactory {
    public static let FormIconFetchOperationKind = PipelineOperationKind(rawValue: "fetch form icons")

    public static func createFormIconFetchRepository(
        url: URL,
        session: TokenAPISession
    ) -> AnyFetchRepository<FormIconFetchRequest, [URL]> {
        AnyFetchRepository(
            FetchRepository<FormIconFetchRequest, [URL]> { input in
                let pipeline = FetchPipelines
                    .default(
                        remote: FormIconFetchRemote(
                            url: url,
                            session: session,
                            eventID: input.eventID
                        ),
                        local: FormIconFetchLocal(eventID: input.eventID),
                        operation: FormIconFetchOperationKind
                    )
                return pipeline.execute()
            }
        )
    }
}
