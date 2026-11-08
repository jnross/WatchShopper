//
//  WatchShopperTests.swift
//  WatchShopperTests
//
//  Created by Joseph Ross on 10/7/21.
//

import XCTest
@testable import WatchShopper

class WatchShopperTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

class RecordingSyncBehavior: ListsViewModelDelegate {
    var updatedLists: [Checklist] = []

    func didReceiveRefreshRequest(listsViewModel: ListsViewModel, from watchSync: WatchSync) {}
    func didActivate(listsViewModel: ListsViewModel, watchSync: WatchSync) {}
    func didUpdateList(_ checklist: Checklist, in listsViewModel: ListsViewModel) {
        updatedLists.append(checklist)
    }
    func didDeleteList(_ checklist: Checklist, in listsViewModel: ListsViewModel) {}
}

class ListsViewModelTests: XCTestCase {
    static let watchSync = WatchSync()

    let older = Date(timeIntervalSince1970: 1_700_000_000)
    let newer = Date(timeIntervalSince1970: 1_700_000_100)

    var syncBehavior: RecordingSyncBehavior!

    override func setUpWithError() throws {
        syncBehavior = RecordingSyncBehavior()
    }

    private func makeList(updated: Date, checked: Bool) -> Checklist {
        Checklist(id: "list-1", title: "Groceries", updated: updated, items: [
            Checklist.Item(id: "item-1", title: "milk", checked: checked),
        ])
    }

    /// Delivers lists as if received from the counterpart device and waits for the main-queue merge.
    private func receive(_ lists: [Checklist], into viewModel: ListsViewModel) {
        viewModel.watchSync(Self.watchSync, updated: lists)
        let merged = expectation(description: "merged")
        DispatchQueue.main.async { merged.fulfill() }
        wait(for: [merged], timeout: 1)
    }

    func testIncomingOlderListDoesNotReplaceLocalEdit() {
        let local = makeList(updated: newer, checked: true)
        let viewModel = ListsViewModel(lists: [local], syncBehaviorDelegate: syncBehavior)

        receive([makeList(updated: older, checked: false)], into: viewModel)

        XCTAssertEqual(viewModel.lists, [local])
        XCTAssertEqual(viewModel.lists.first?.updated, newer)
        XCTAssertTrue(syncBehavior.updatedLists.isEmpty)
    }

    func testIncomingListWithSameTimestampDoesNotReplaceLocal() {
        let local = makeList(updated: older, checked: true)
        let viewModel = ListsViewModel(lists: [local], syncBehaviorDelegate: syncBehavior)

        receive([makeList(updated: older, checked: false)], into: viewModel)

        XCTAssertEqual(viewModel.lists, [local])
        XCTAssertTrue(syncBehavior.updatedLists.isEmpty)
    }

    func testIncomingNewerListReplacesLocalAndIsPersisted() {
        let viewModel = ListsViewModel(lists: [makeList(updated: older, checked: false)], syncBehaviorDelegate: syncBehavior)
        let incoming = makeList(updated: newer, checked: true)

        receive([incoming], into: viewModel)

        XCTAssertEqual(viewModel.lists, [incoming])
        XCTAssertEqual(viewModel.lists.first?.updated, newer)
        XCTAssertEqual(syncBehavior.updatedLists, [incoming])
    }

    func testIncomingUnknownListIsAddedButNotPersisted() {
        let viewModel = ListsViewModel(lists: [], syncBehaviorDelegate: syncBehavior)
        let incoming = makeList(updated: older, checked: false)

        receive([incoming], into: viewModel)

        XCTAssertEqual(viewModel.lists, [incoming])
        XCTAssertTrue(syncBehavior.updatedLists.isEmpty)
    }

    func testLocalEditStampsUpdated() {
        let viewModel = ListsViewModel(lists: [makeList(updated: older, checked: false)], syncBehaviorDelegate: syncBehavior)

        viewModel.listDidUpdate(makeList(updated: older, checked: true))

        let saved = viewModel.lists.first!
        XCTAssertTrue(saved.items.first!.checked)
        XCTAssertGreaterThan(saved.updated, older)
        XCTAssertEqual(syncBehavior.updatedLists.map(\.updated), [saved.updated])
    }

    func testUnchangedLocalSaveIsIgnored() {
        let local = makeList(updated: older, checked: false)
        let viewModel = ListsViewModel(lists: [local], syncBehaviorDelegate: syncBehavior)

        viewModel.listDidUpdate(local)

        XCTAssertEqual(viewModel.lists.first?.updated, older)
        XCTAssertTrue(syncBehavior.updatedLists.isEmpty)
    }
}
