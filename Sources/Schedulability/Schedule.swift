import DDKit

typealias ScheduleSet = MFDD<ScheduleKey, ScheduleValue>

/// A MFDD key representing either a core or a task.
///
/// This struct acts as a convenience wrapper around a simple integer value. It uses the 63 least
/// significant bits to store an ID and uses the last bit to store whether it's a core or task ID.
/// As a result, the raw value of a core ID is always negative.
struct ScheduleKey: Hashable {

  fileprivate let value: Int64

  var isCoreID: Bool { value & (1 << 63) != 0 }

  var coreID: Int { Int((value << 1) >> 1) }

  var isTaskID: Bool { !isCoreID }

  var taskID: Int { Int(value) }

  static func core(id: Int) -> ScheduleKey {
    return ScheduleKey(value: Int64(id | 1 << 63))
  }

  static func task(id: Int) -> ScheduleKey {
    return ScheduleKey(value: Int64(id))
  }

}

extension ScheduleKey: Comparable {

  static func < (lhs: ScheduleKey, rhs: ScheduleKey) -> Bool {
    lhs.value < rhs.value
  }

}

extension ScheduleKey: CustomStringConvertible {

  var description: String {
    return value & (1 << 63) != 0
      ? "core(\(value & ~(1 << 63)))"
      : "task(\(value))"
  }

}

/// A MFDD arc value representing a core/clock pair.
///
/// This struct acts as a convenience wrapper around a simple integer value. It uses the 32 most
/// significant bits to a core ID and the 32 least significant bits to store a clock value.
struct ScheduleValue: Hashable {

  private let value: Int64

  var coreID: Int { Int(value >> 32) }

  var clock: Int { Int((value << 32) >> 32)  }

  init(coreID: Int = 0, clock: Int) {
    value = Int64(coreID << 32) | Int64(clock)
  }

}

extension ScheduleValue: CustomStringConvertible {

  var description: String {
    return "(coreID: \(coreID), clock: \(clock))"
  }

}
