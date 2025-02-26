import Foundation

public struct ScanResult {
    enum Annotation {
        case unused
        case assignOnlyProperty
        case redundantProtocol(references: Set<Reference>)
        case redundantPublicAccessibility(modules: Set<String>)
    }

    let declaration: Declaration
    let annotation: Annotation
}
