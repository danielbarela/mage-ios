// 
//     
//  FormUseCaseModule.swift
//  MAGE
//
// 

import UseCaseFactory

@MainActor
enum FormUseCaseModule: UseCaseModule {
    static func build(deps: AppDependencies) -> [AnyUseCaseRegistration] {
        [
            .init { factory in
                factory.register(.GetEventFormIconsUseCase) {
                    return GetEventFormIconsUseCase(
                        formIconFetch: deps.formIconFetch
                    )
                }
            }
        ]
    }
}

extension UseCaseKey {
    static var GetEventFormIconsUseCase: UseCaseKey<GetEventFormIconsUseCase> {
        .init()
    }
}
