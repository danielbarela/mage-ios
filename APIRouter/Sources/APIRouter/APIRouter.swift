import Foundation
import Alamofire

public protocol APIRouter: URLRequestConvertible {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
}

public enum GeneralError: Error, Equatable {
    case expiredToken
    case coreDataUnavailable
    case writeContextUnavailable
    case noEventProvided
    case serverError(error: String)
    case noSessionExists
}

extension GeneralError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .expiredToken:
            return "Token is expired."
        case .coreDataUnavailable:
            return "Core Data is unavailable."
        case .writeContextUnavailable:
            return "Write context is unavailable."
        case .noEventProvided:
            return "No Event ID was provided."
        case .serverError(let error):
            return error
        case .noSessionExists:
            return "No Server Session Exists"
            
        }
    }
}

extension GeneralError: Identifiable {
    public var id: String? {
        errorDescription
    }
}
