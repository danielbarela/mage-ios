//
//  FormRouter.swift
//  Form
//


import Foundation
import Alamofire
import APIRouter

struct FormRouter: APIRouter {
    let baseURL: URL

    enum Endpoint {
        case fetchIcons(eventId: NSNumber)
        
        var method: HTTPMethod {
            switch self {
            case .fetchIcons:
                return .get
            }
        }
        
        var path: String {
            switch self {
            case .fetchIcons(let eventId):
                return "/api/events/\(eventId)/form/icons.zip"
            }
        }
        
        var parameters: Parameters? {
            switch self {
            case .fetchIcons:
                return nil
            }
        }
    }
    
    let endpoint: Endpoint

    var path: String { endpoint.path }
    var method: HTTPMethod { endpoint.method }
    var parameters: Parameters? { endpoint.parameters }
    
    func asURLRequest() throws -> URLRequest {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue

        urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)

        return urlRequest
    }
}
