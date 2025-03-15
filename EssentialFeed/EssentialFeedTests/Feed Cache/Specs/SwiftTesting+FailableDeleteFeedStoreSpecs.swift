//
//  SwiftTesting+FailableDeleteFeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

import EssentialFeed
import Testing

extension FailableDeleteFeedStoreSpecs where Self: EFTesting {
    func assertThatDeleteDeliversErrorOnDeletionError(on sut: FeedStore,
                                                      fileID: String = #fileID, filePath: String = #filePath,
                                                      line: Int = #line, column: Int = #column) async {
        let deletionError = await deleteCache(from: sut)
        #expect(deletionError != nil,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
    }
    
    func assertThatDeleteHasNoSideEffectsOnDeletionError(on sut: FeedStore,
                                                         fileID: String = #fileID, filePath: String = #filePath,
                                                         line: Int = #line, column: Int = #column) async {
        await deleteCache(from: sut)
        
        await expect(sut, toRetrieve: .success(.empty),
                     fileID: fileID, filePath: filePath, line: line, column: column)
    }
}
