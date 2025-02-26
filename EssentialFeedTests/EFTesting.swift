//
//  EFTesting.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 26/02/25.
//

import Testing

class EFTesting {
    typealias MemoryLeakCheckable = AnyObject & Sendable
    
    private var checks = [MemoryLeakCheck]()
    
    func trackForMemoryLeak<T: MemoryLeakCheckable>(_ instanceFactory: @autoclosure () -> T,
                                                    sourceLocation: SourceLocation = .__here()) {
        checks.append(.init(instanceFactory(), sourceLocation: sourceLocation))
    }
    
    private struct MemoryLeakCheck {
        let sourceLocation: SourceLocation
        private weak var weakReference: MemoryLeakCheckable?
        var isLeaking: Bool { weakReference != nil }
        init(_ weakReference: MemoryLeakCheckable, sourceLocation: SourceLocation) {
            self.weakReference = weakReference
            self.sourceLocation = sourceLocation
        }
    }
    
    deinit {
        for check in checks {
            #expect(check.isLeaking == false, "Potential Memory Leak detected", sourceLocation: check.sourceLocation)
        }
    }
}
