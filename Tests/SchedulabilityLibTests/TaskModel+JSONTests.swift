import XCTest

@testable import SchedulabilityLib

final class TaskModelJSONTests: XCTestCase {
  
  func testInitFromJSON() {
    let json =
      """
      [
        {
          "id": 3,
          "wcet": 1
        },
        {
          "id": 2,
          "wcet": 1,
          "release": 1
        },
        {
          "id": 1,
          "wcet": 3,
          "deadline": 4,
          "dependencies": [ 3 ]
        },
        {
          "id": 0,
          "wcet": 2,
          "dependencies": [ 2, 3 ]
        }
      ]
      """.data(using: .utf8)

    let taskModel = try? TaskModel(fromJSON: json!)
    
    XCTAssertNotNil(taskModel)
    
    let task0 = taskModel?.tasks[0]
    XCTAssertNotNil(task0)
    XCTAssertEqual(task0?.id, 0)
    XCTAssertEqual(task0?.wcet, 2)
    XCTAssertEqual(task0?.dependencies.count, 2)
    
    let task1 = taskModel?.tasks[1]
    XCTAssertNotNil(task1)
    XCTAssertEqual(task1?.id, 1)
    XCTAssertEqual(task1?.wcet, 3)
    XCTAssertEqual(task1?.deadline, 4)
    XCTAssertEqual(task1?.dependencies.count, 1)
    
    let task2 = taskModel?.tasks[2]
    XCTAssertNotNil(task2)
    XCTAssertEqual(task2?.id, 2)
    XCTAssertEqual(task2?.wcet, 1)
    XCTAssertEqual(task2?.release, 1)
    
    let task3 = taskModel?.tasks[3]
    XCTAssertNotNil(task3)
    XCTAssertEqual(task3?.id, 3)
    XCTAssertEqual(task3?.wcet, 1)
  }

  func testMissingContext() {
    let json = "[ {} ]".data(using: .utf8)
    let decoder = JSONDecoder()

    XCTAssertThrowsError(try decoder.decode(TaskModel.self, from: json!)) { error in
      XCTAssertEqual(
        error as? TaskDecodingError,
        TaskDecodingError.missingOrInvalidDecodingContext)
    }
  }
  
  func testInvalidInput() {
    let json =
      """
      {
        [
          { "id": 0 }
        ]
      }
      """.data(using: .utf8)
    
    XCTAssertThrowsError(try TaskModel(fromJSON: json!)) { error in
      XCTAssert(error is DecodingError)
    }
  }
  
  func testMissingField() {
    let json =
      """
      [
        {
          "wcet": 1
        }
      ]
      """.data(using: .utf8)

    XCTAssertThrowsError(try TaskModel(fromJSON: json!)) { error in
      XCTAssert(error is DecodingError)
    }
  }

  func testUndefinedDependency() {
    let json =
      """
      [
        {
          "id": 1,
          "wcet": 1
        },
        {
          "id": 0,
          "wcet": 1,
          "dependencies": [ 2 ]
        }
      ]
      """.data(using: .utf8)

    XCTAssertThrowsError(try TaskModel(fromJSON: json!)) { error in
      XCTAssertEqual(error as? TaskDecodingError, TaskDecodingError.undefinedDependency)
    }
  }
  
}
