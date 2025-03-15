//
//  SwiftTesting+FailableInsertFeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

import EssentialFeed
import Testing

extension FailableInsertFeedStoreSpecs where Self: EFTesting {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore,
                                                       fileID: String = #fileID, filePath: String = #filePath,
                                                       line: Int = #line, column: Int = #column) async {
        let insertionError = await insert(([], Date()), to: sut)
        #expect(insertionError != nil,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore,
                                                         fileID: String = #fileID, filePath: String = #filePath,
                                                         line: Int = #line, column: Int = #column) async {
        await insert((getUniqueImageFeed().local, Date()), to: sut)
        
        await expect(sut, toRetrieve: .success(nil),
                     fileID: fileID, filePath: filePath, line: line, column: column)
    }
}
