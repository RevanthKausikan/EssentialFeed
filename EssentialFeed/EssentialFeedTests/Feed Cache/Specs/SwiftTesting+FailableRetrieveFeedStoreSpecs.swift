//
//  SwiftTesting+FailableRetrieveFeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

import EssentialFeed
import Testing

extension FailableRetrieveFeedStoreSpecs where Self: EFTesting {
    func assertThatRetrieveDeliversFailureOnRetrievalError(on sut: FeedStore,
                                                           fileID: String = #fileID, filePath: String = #filePath,
                                                           line: Int = #line, column: Int = #column) async {
        await expect(sut, toRetrieve: .failure(anyError),
                     fileID: fileID, filePath: filePath, line: line, column: column)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnFailure(on sut: FeedStore,
                                                     fileID: String = #fileID, filePath: String = #filePath,
                                                     line: Int = #line, column: Int = #column) async {
        await expect(sut, toRetrieveTwice: .failure(anyError),
                     fileID: fileID, filePath: filePath, line: line, column: column)
    }
}
