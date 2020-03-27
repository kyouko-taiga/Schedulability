import DDKit

extension MFDD {

  public final class InclusiveKeyFilter: Morphism, MFDDSaturable {

    public typealias DD = MFDD

    /// The keys filtered by this morphism.
    public let keys: [Key]

    /// The next morphism to apply once the first key has been processed.
    private var next: SaturatedMorphism<InclusiveKeyFilter>?

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: MFDDFactory<Key, Value>

    /// The morphism's cache.
    private var cache: [MFDD.Pointer: MFDD.Pointer] = [:]

    public var lowestRelevantKey: Key { keys.min()! }

    fileprivate init(keys: Set<Key>, factory: MFDDFactory<Key, Value>) {
      assert(!keys.isEmpty, "Sequence of keys to filter is empty.")

      self.keys = keys.sorted()
      self.next = keys.count > 1
        ? factory.morphisms.saturate(
          factory.morphisms.filter(containingKeys: self.keys.dropFirst()))
        : nil

      self.factory = factory
    }

    public func apply(on pointer: MFDD.Pointer) -> MFDD.Pointer {
      // Check for trivial cases.
      guard !factory.isTerminal(pointer)
        else { return factory.zero.pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      // Apply the morphism.
      let result: MFDD.Pointer
      if pointer.pointee.key < keys[0] {
        result = factory.node(
          key: pointer.pointee.key,
          take: pointer.pointee.take.mapValues(apply(on:)),
          skip: apply(on: pointer.pointee.skip))
      } else if pointer.pointee.key == keys[0] {
        let take = pointer.pointee.take

        result = factory.node(
          key: pointer.pointee.key,
          take: next != nil ? take.mapValues(next!.apply(on:)) : take,
          skip: factory.zero.pointer)
      } else {
        result = factory.zero.pointer
      }

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(keys)
    }

    public static func == (lhs: InclusiveKeyFilter, rhs: InclusiveKeyFilter) -> Bool {
      lhs === rhs
    }

  }

  public final class ExclusiveKeyFilter: Morphism, MFDDSaturable {

    public typealias DD = MFDD

    /// The keys filtered by this morphism.
    public let keys: [Key]

    /// The next morphism to apply once the first key has been processed.
    private var next: SaturatedMorphism<ExclusiveKeyFilter>?

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: MFDDFactory<Key, Value>

    /// The morphism's cache.
    private var cache: [MFDD.Pointer: MFDD.Pointer] = [:]

    public var lowestRelevantKey: Key { keys.min()! }

    fileprivate init(keys: Set<Key>, factory: MFDDFactory<Key, Value>) {
      assert(!keys.isEmpty, "Sequence of keys to filter is empty.")

      self.keys = keys.sorted()
      self.next = keys.count > 1
        ? factory.morphisms.saturate(
          factory.morphisms.filter(excludingKeys: self.keys.dropFirst()))
        : nil

      self.factory = factory
    }

    public func apply(on pointer: MFDD.Pointer) -> MFDD.Pointer {
      // Check for trivial cases.
      guard !factory.isTerminal(pointer)
        else { return pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      // Apply the morphism.
      let result: MFDD.Pointer
      if pointer.pointee.key < keys[0] {
        result = factory.node(
          key: pointer.pointee.key,
          take: pointer.pointee.take.mapValues(apply(on:)),
          skip: apply(on: pointer.pointee.skip))
      } else if pointer.pointee.key == keys[0] {
        return next?.apply(on: pointer.pointee.skip) ?? pointer.pointee.skip
      } else {
        result = next?.apply(on: pointer) ?? pointer
      }

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(keys)
    }

    public static func == (lhs: ExclusiveKeyFilter, rhs: ExclusiveKeyFilter) -> Bool {
      lhs === rhs
    }

  }

}

extension MFDDMorphismFactory {

  /// Creates an _inclusive key filter_ morphism.
  ///
  /// - Parameter keys: A sequence with the keys that the member must contain.
  public func filter<S>(containingKeys keys: S) -> MFDD<Key, Value>.InclusiveKeyFilter
    where S: Sequence, S.Element == Key
  {
    let morphism =  MFDD<Key, Value>.InclusiveKeyFilter(keys: Set(keys), factory: nodeFactory)
    return self.uniquify(morphism)
  }


  /// Creates an _exclusive key filter_ morphism.
  ///
  /// - Parameter keys: A sequence with the keys that the member must not contain.
  public func filter<S>(excludingKeys keys: S) -> MFDD<Key, Value>.ExclusiveKeyFilter
    where S: Sequence, S.Element == Key
  {
    let morphism =  MFDD<Key, Value>.ExclusiveKeyFilter(keys: Set(keys), factory: nodeFactory)
    return self.uniquify(morphism)
  }

}
