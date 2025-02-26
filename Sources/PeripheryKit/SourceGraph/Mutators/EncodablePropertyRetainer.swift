import Foundation
import Shared

/// Retains properties of discrete conforming declarations that directly, or indirectly conform to `Encodable`.
///
/// The Swift compiler synthesizes code for `Encodable` that is not exposed in the index store. We therefore must
/// assume that all properties are in use, as they may be referenced by synthesized code.
final class EncodablePropertyRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let externalCodableProtocols: [String]

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.externalCodableProtocols = configuration.externalEncodableProtocols + configuration.externalCodableProtocols
    }

    func mutate() {
        graph
            .declarations(ofKinds: Declaration.Kind.discreteConformableKinds)
            .lazy
            .filter { self.hasEncodableConformance($0) }
            .forEach {
                $0.declarations
                    .lazy
                    .filter { $0.kind == .varInstance }
                    .forEach { graph.markRetained($0) }
            }
    }

    // MARK: - Private

    private func hasEncodableConformance(_ decl: Declaration) -> Bool {
        graph
            .inheritedTypeReferences(of: decl)
            .contains { isEncodableReference($0) }
    }

    private func isEncodableReference(_ ref: Reference) -> Bool {
        if ref.kind == .protocol && ref.name == "Encodable" || ref.kind == .typealias && ref.name == "Codable" {
            return true
        }

        if let name = ref.name {
            if graph.isExternal(ref), externalCodableProtocols.contains(name) {
                return true
            }
        }

        return false
    }
}
