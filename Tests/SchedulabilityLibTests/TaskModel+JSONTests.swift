import XCTest

@testable import SchedulabilityLib

final class TaskModelJSONTests: XCTestCase {
  
  func testInitTaskModelWithJSON() {
    let json = """
    {
      "t0": {
        "id": 0,
        "wcet": 2,
        "dependencies": ["t2", "t3"]
      },
      
      "t1": {
        "id": 1,
        "wcet": 3,
        "deadline": 4,
        "dependencies": ["t3"]
      },
      
      "t2": {
        "id": 2,
        "wcet": 1,
        "release": 1
      },
      
      "t3": {
        "id": 3,
        "wcet": 1
      }
    }
    """.data(using: .utf8)
    
    let taskModel = try? TaskModel(from: json!)
    
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
  
  func testInvalidConfiguration() {
    let json = """
    {
      "t0": [
        {"id": 0}
      ]
    }
    """.data(using: .utf8)
    
    XCTAssertThrowsError(try TaskModel(from: json!)) { error in
      XCTAssertEqual(error as! SerializationError, SerializationError.invalidConfiguration)
    }
  }
  
  func testMissingField() {
    let json = """
    {
      "t0": {
        "wcet": 1
      }
    }
    """.data(using: .utf8)
    
    XCTAssertThrowsError(try TaskModel(from: json!)) { error in
      XCTAssertEqual(error as! SerializationError,
                     SerializationError.missing(task: "t0", field: "id"))
    }
  }
  
  func testInvalidField() {
    let json = """
    {
      "t0": {
        "id": 0,
        "wcet": 1,
        "dependencies": ["t2"]
      },

      "t1": {
        "id": 1,
        "wcet": 1
      }
    }
    """.data(using: .utf8)
    
    XCTAssertThrowsError(try TaskModel(from: json!)) { error in
      XCTAssertEqual(error as! SerializationError,
                     SerializationError.invalid(task: "t0", field: "dependency t2"))
    }
  }
  
  func testCircularDepencency() {
    let json = """
    {
      "t0": {
        "id": 0,
        "wcet": 1,
        "dependencies": ["t1"]
      },

      "t1": {
        "id": 1,
        "wcet": 1,
        "dependencies": ["t0"]
      }
    }
    """.data(using: .utf8)
    
    XCTAssertThrowsError(try TaskModel(from: json!)) { error in
      let serializationError = error as! SerializationError
      XCTAssert(
        serializationError == SerializationError.circularDependency(task1: "t0", task2: "t1") ||
        serializationError == SerializationError.circularDependency(task1: "t1", task2: "t0")
      )
    }
  }
  
}
