//
//  Queue.swift
//  FlatBread
//
//  Created by 서준일 on 12/4/25.
//

import Foundation

/// 원형 큐 구현
struct CircularQueue<Element> {
    
    // MARK: - Properties
    private var storage: [Element?]
    private var readIndex: Int = 0
    private var writeIndex: Int = 0
    private var _count: Int = 0
    
    private let initialCapacity: Int
    
    var count: Int { _count }
    var isEmpty: Bool { _count == 0 }
    var isFull: Bool { _count == storage.count }
    
    var peek: Element? {
        isEmpty ? nil : storage[readIndex]
    }
    
    // MARK: - Init
    
    /// 지정된 용량으로 원형 큐 생성
    init(capacity: Int = 16) {
        self.initialCapacity = capacity
        self.storage = Array(repeating: nil, count: capacity)
    }
    
    // MARK: - Methods
    
    /// 큐의 끝에 요소 추가
    mutating func enqueue(_ value: Element) {
        if isFull {
            resize()
        }
        
        storage[writeIndex] = value
        writeIndex = (writeIndex + 1) % storage.count
        _count += 1
    }
    
    /// 큐의 앞에서 요소 제거 및 반환
    @discardableResult
    mutating func dequeue() -> Element? {
        guard !isEmpty else { return nil }

        let element = storage[readIndex]
        storage[readIndex] = nil
        readIndex = (readIndex + 1) % storage.count
        _count -= 1

        return element
    }
    
    /// 큐의 모든 요소 제거
    mutating func removeAll(keepingCapacity: Bool = false) {
        if keepingCapacity {
            storage = Array(repeating: nil, count: storage.count)
        } else {
            storage = Array(repeating: nil, count: initialCapacity)
        }
        
        readIndex = 0
        writeIndex = 0
        _count = 0
    }
    
    
    // MARK: - Private Methods
    
    private mutating func resize() {
        let newCapacity = storage.count * 2
        var newStorage: [Element?] = Array(repeating: nil, count: newCapacity)
        
        for (index, element) in enumerated() {
            newStorage[index] = element
        }
        
        storage = newStorage
        readIndex = 0
        writeIndex = _count
    }
}

// MARK: - Sequence

extension CircularQueue: Sequence {
    func makeIterator() -> CircularQueueIterator {
        CircularQueueIterator(queue: self)
    }
    
    struct CircularQueueIterator: IteratorProtocol {
        private let queue: CircularQueue<Element>
        private var currentIndex: Int
        private var elementsRemaining: Int
        
        init(queue: CircularQueue<Element>) {
            self.queue = queue
            self.currentIndex = queue.readIndex
            self.elementsRemaining = queue.count
        }
        
        mutating func next() -> Element? {
            guard elementsRemaining > 0 else { return nil }
            
            let element = queue.storage[currentIndex]
            currentIndex = (currentIndex + 1) % queue.storage.count
            elementsRemaining -= 1
            
            return element
        }
    }
}

// MARK: - Collection

extension CircularQueue: Collection {
    var startIndex: Int { 0 }
    var endIndex: Int { count }
    
    func index(after i: Int) -> Int {
        i + 1
    }
    
    subscript(position: Int) -> Element {
        precondition(position >= 0 && position < count, "Index out of range")
        let actualIndex = (readIndex + position) % storage.count
        return storage[actualIndex]!
    }
}

// MARK: - CustomStringConvertible

extension CircularQueue: CustomStringConvertible where Element: CustomStringConvertible {
    var description: String {
        let elements = map { $0.description }.joined(separator: ", ")
        return "CircularQueue([\(elements)])"
    }
}
