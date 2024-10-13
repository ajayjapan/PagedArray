import Testing
@testable import PagedArray

class PagedArrayTests {
    // These three parameters should be modifiable without any
    // test failing as long as the resulting array has at least three pages.
    let ArrayCount = 100
    let PageSize = 10
    let StartPageIndex = 10

    var pagedArray: PagedArray<Int>!

    var firstPage: [Int]!
    var secondPage: [Int]!

    init() {
        pagedArray = PagedArray(count: ArrayCount/2, pageSize: PageSize, startPage: StartPageIndex)

        // Fill up two pages
        firstPage = Array(1...PageSize)
        secondPage = Array(PageSize+1...PageSize*2)

        pagedArray.set(firstPage, forPage: StartPageIndex)
        pagedArray.set(secondPage, forPage: StartPageIndex+1)

        pagedArray.count = ArrayCount
    }

    @Test("Test Size Correct")
    func testSizeIsCorrect() async throws {
        #expect(pagedArray.count == ArrayCount)
        #expect(Array(pagedArray).count == ArrayCount)
    }

   @Test("Test Generator Works")
    func testGeneratorWorks() async throws {
        let generatedArray = Array(pagedArray.makeIterator())
        #expect(generatedArray.count == ArrayCount)
        #expect(generatedArray[0] == firstPage[0])
    }

    @Test("Test Subscripting Works For AllValidIndexesWithoutHittingAssertions")
    func testSubscriptingWorksForAllValidIndexesWithoutHittingAssertions() async throws {
        for i in pagedArray.startIndex..<pagedArray.endIndex {
            let _ = pagedArray[i]
        }
    }

    @Test("Test Can Replace Values Using Subscript")
    func testCanReplaceValuesUsingSubscript() async throws {
        pagedArray[0] = 666
        #expect(pagedArray[0] == 666)
    }
    
    @Test("Test Can Set LastPageWithUnevenSize")
    func testCanSetLastPageWithUnevenSize() async throws {
        let elements = Array(1...pagedArray.pageSize)
        pagedArray.set(elements, forPage: pagedArray.lastPage)
        #expect(pagedArray.elements[pagedArray.lastPage] == elements)
    }

    @Test("Test Changing Count Changes Last Page Indexes Range")
    func testChangingCountChangesLastPageIndexesRange() async throws {
        let originalIndexes = pagedArray.indexes(for: pagedArray.lastPage)
        pagedArray.count += 1
        let newIndexes = pagedArray.indexes(for: pagedArray.lastPage)
        #expect(originalIndexes != newIndexes)
    }

    @Test("Test Changing Count Changes Last PageIndex")
    func testChangingCountChangesLastPageIndex() async throws {
        let originalLastPageIndex = pagedArray.lastPage
        pagedArray.count += PageSize
        #expect(pagedArray.lastPage == originalLastPageIndex+1)
    }

    @Test("Test Returns Nil For Index Corresponding To Page Not Yet Set")
    func testReturnsNilForIndexCorrespondingToPageNotYetSet() async throws {
        #expect(pagedArray[PageSize*2] == nil)
    }

    @Test("Test Loaded Elements Equal To Combined Pages")
    func testLoadedElementsEqualToCombinedPages() async throws {
        #expect(pagedArray.loadedElements == firstPage + secondPage)
    }

    @Test("Test Contains Correct Amount Of Real Values")
    func testContainsCorrectAmountOfRealValues() async throws {
        let valuesCount = pagedArray.filter{ $0 != nil }.count
        #expect(valuesCount == PageSize*2)
    }

    @Test("Test Index Range Works For First Page")
    func testIndexRangeWorksForFirstPage() async throws {
        #expect(pagedArray.indexes(for: StartPageIndex) == (0..<PageSize))
    }

    @Test("Test Index Range Works For Second Page")
    func testIndexRangeWorksForSecondPage() async throws {
        #expect(pagedArray.indexes(for: StartPageIndex+1) == (PageSize..<PageSize*2))
    }

    @Test("Test Index Range Works For Last Page")
    func testIndexRangeWorksForLastPage() async throws {
        #expect(pagedArray.indexes(for: pagedArray.lastPage) == (PageSize*(calculatedLastPageIndex()-StartPageIndex)..<ArrayCount))
    }

    @Test("Test Remove Page Removes Page")
    func testRemovePageRemovesPage() async throws {
        let page = StartPageIndex+2
        pagedArray.remove(page)
        for index in pagedArray.indexes(for: page) {
            #expect(pagedArray[index] == nil)
        }
    }

    @Test("Test Remove All Pages Removes All Loaded Elements")
    func testRemoveAllPagesRemovesAllLoadedElements() async throws {
        pagedArray.removeAllPages()
        #expect(pagedArray.loadedElements.isEmpty)
    }

    @Test("Test Last Page Index Implementation")
    func testLastPageIndexImplementation() async throws {
        #expect(pagedArray.lastPage == calculatedLastPageIndex())
    }

    @Test("Test Setting Empty Elements On Zero Count Array")
    func testSettingEmptyElementsOnZeroCountArray() async throws {
        var emptyArray: PagedArray<Int> = PagedArray(count: 0, pageSize: 10)
        emptyArray.set([], forPage: 0)
        #expect(emptyArray.loadedElements.isEmpty)
    }

    // MARK: High Chaparall Mode tests
    @Test("Test Adding Extra Element In Last Page Updates Count In High Chaparall Mode")
    func testAddingExtraElementInLastPageUpdatesCountInHighChaparallMode() async throws {
        pagedArray.updatesCountWhenSettingPages = true
        
        let lastPageSize = pagedArray.size(for: pagedArray.lastPage)+1 
        let lastPage = Array(1...lastPageSize)

        pagedArray.set(lastPage, forPage: pagedArray.lastPage)

        #expect(pagedArray.count == ArrayCount+1)
    }

    @Test("Test Count Is Changed By Adding Extra Page In High Chaparall Mode")
    func testCountIsChangedByAddingExtraPageInHighChaparallMode() async throws {
        pagedArray.updatesCountWhenSettingPages = true
        
        let extraPage = Array(1...PageSize)
        
        pagedArray.set(extraPage, forPage: pagedArray.lastPage+2)

        var expectedSize = ArrayCount+PageSize*2
        if ArrayCount%PageSize > 0 {
            expectedSize += PageSize-ArrayCount%PageSize
        }

        #expect(pagedArray.count == expectedSize)
    }

    /*
     func testSettingPageWithLowerSizeUpdatesCountInHighChaparallMode() {

         pagedArray.updatesCountWhenSettingPages = true // YEE-HAW

         pagedArray.set([0], forPage: StartPageIndex)
         XCTAssertEqual(pagedArray.count, ArrayCount-PageSize+1, "Count did not update when setting a page with lower length than expected")
     }
     */
    @Test("Test Setting Page With Lower Size Updates Count In High Chaparall Mode")
    func testSettingPageWithLowerSizeUpdatesCountInHighChaparallMode() async throws {
        pagedArray.updatesCountWhenSettingPages = true

        pagedArray.set([0], forPage: StartPageIndex)

        #expect(pagedArray.count == ArrayCount-PageSize+1)
    }


    // MARK: Utility
    fileprivate func calculatedLastPageIndex() -> Int {
        if ArrayCount%PageSize == 0 {
            return ArrayCount/PageSize+StartPageIndex-1
        } else {
            return ArrayCount/PageSize+StartPageIndex
        }
    }
}

private extension PagedArray {
    func size(for page: PageIndex) -> Int {
        let indexes = self.indexes(for: page)
        return indexes.endIndex-indexes.startIndex
    }
}

/*
 // MARK: Tests

 func testSizeIsCorrect() {
     XCTAssertEqual(pagedArray.count, ArrayCount, "Paged array has wrong size")
     XCTAssertEqual(Array(pagedArray).count, ArrayCount, "Paged array elements has wrong size")
 }

 func testGeneratorWorks() {
     let generatedArray = Array(pagedArray.makeIterator())

     XCTAssertEqual(generatedArray.count, ArrayCount, "Generated array has wrong count")
     XCTAssertEqual(generatedArray[0], firstPage[0], "Generated array has wrong content")
 }

 func testSubscriptingWorksForAllValidIndexesWithoutHittingAssertions() {
     for i in pagedArray.startIndex..<pagedArray.endIndex {
         let _ = pagedArray[i]
     }
 }

 func testCanReplaceValuesUsingSubscript() {
     pagedArray[0] = 666
     XCTAssertEqual(pagedArray[0], 666)
 }

 func testCanSetLastPageWithUnevenSize() {
     let elements = Array(1...pagedArray.size(for: pagedArray.lastPage))
     pagedArray.set(elements, forPage: pagedArray.lastPage)
 }

 func testChangingCountChangesLastPageIndexesRange() {
     let originalIndexes = pagedArray.indexes(for: pagedArray.lastPage)
     pagedArray.count += 1
     let newIndexes = pagedArray.indexes(for: pagedArray.lastPage)

     XCTAssertNotEqual(originalIndexes, newIndexes, "Indexes for last page did not change even though total count changed")
 }

 func testChangingCountChangesLastPageIndex() {
     let originalLastPageIndex = pagedArray.lastPage
     pagedArray.count += PageSize

     XCTAssertEqual(pagedArray.lastPage, originalLastPageIndex+1, "Number of pages did not change after total count was increased with one page size")
 }

 func testReturnsNilForIndexCorrespondingToPageNotYetSet() {
     if pagedArray[PageSize*2] != nil {
         XCTAssert(false, "Paged array should return nil for index belonging to a page not yet set")
     }
 }

 func testLoadedElementsEqualToCombinedPages() {
     XCTAssertEqual(pagedArray.loadedElements, firstPage + secondPage, "Loaded pages doesn't match set pages")
 }

 func testContainsCorrectAmountOfRealValues() {
     let valuesCount = pagedArray.filter{ $0 != nil }.count
     XCTAssertEqual(valuesCount, PageSize*2, "Incorrect count of real values inside paged array")
 }

 func testIndexRangeWorksForFirstPage() {
     XCTAssertEqual(pagedArray.indexes(for: StartPageIndex), (0..<PageSize), "Incorrect range for page")
 }

 func testIndexRangeWorksForSecondPage() {
     XCTAssertEqual(pagedArray.indexes(for: StartPageIndex+1), (PageSize..<PageSize*2), "Incorrect range for page")
 }

 func testIndexRangeWorksForLastPage() {
     XCTAssertEqual(pagedArray.indexes(for: pagedArray.lastPage), (PageSize*(calculatedLastPageIndex()-StartPageIndex)..<ArrayCount), "Incorrect range for page")
 }

 func testRemovePageRemovesPage() {
     let page = StartPageIndex+2
     pagedArray.remove(page)
     for index in pagedArray.indexes(for: page) {
         if pagedArray[index] != nil {
             XCTAssert(false, "Paged array should return nil for index belonging to a removed page")
         }
     }
 }

 func testRemoveAllPagesRemovesAllLoadedElements() {
     pagedArray.removeAllPages()
     XCTAssertEqual(pagedArray.loadedElements.count, 0, "RemoveAllPages should remove all loaded elements")
 }

 func testLastPageIndexImplementation() {
     XCTAssertEqual(pagedArray.lastPage, calculatedLastPageIndex(), "Incorrect index for last page")
 }

 func testSettingEmptyElementsOnZeroCountArray() {
     var emptyArray: PagedArray<Int> = PagedArray(count: 0, pageSize: 10)
     emptyArray.set(Array(), forPage: 0)
 }


 // MARK: High Chaparall Mode tests

 func testAddingExtraElementInLastPageUpdatesCountInHighChaparallMode() {

     pagedArray.updatesCountWhenSettingPages = true // YEE-HAW

     let lastPageSize = pagedArray.size(for: pagedArray.lastPage)+1 // Simulate finding an extra element from the API
     let lastPage = Array(1...lastPageSize)

     pagedArray.set(lastPage, forPage: pagedArray.lastPage)

     XCTAssertEqual(pagedArray.count, ArrayCount+1, "Count did not increase when setting a bigger page than expected")
 }

 func testCountIsChangedByAddingExtraPageInHighChaparallMode() {

     pagedArray.updatesCountWhenSettingPages = true // YEE-HAW

     let extraPage = Array(1...PageSize)

     pagedArray.set(extraPage, forPage: pagedArray.lastPage+2)

     var expectedSize = ArrayCount+PageSize*2
     if ArrayCount%PageSize > 0 {
         expectedSize += PageSize-ArrayCount%PageSize
     }


     XCTAssertEqual(pagedArray.count, expectedSize, "Count did not update when adding extra pages")
 }

 func testSettingPageWithLowerSizeUpdatesCountInHighChaparallMode() {

     pagedArray.updatesCountWhenSettingPages = true // YEE-HAW

     pagedArray.set([0], forPage: StartPageIndex)
     XCTAssertEqual(pagedArray.count, ArrayCount-PageSize+1, "Count did not update when setting a page with lower length than expected")
 }
 */
