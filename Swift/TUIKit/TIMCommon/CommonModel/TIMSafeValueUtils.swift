
public extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }

    var safeValue: String {
        return self as String? ?? ""
    }
}

public extension Optional where Wrapped == Data {
    var safeValue: Data {
        return self as Data? ?? Data()
    }
}

public extension Character {
    var safeValue: Character {
        return self as Character? ?? " "
    }
}

public extension NSArray {
    func toOptionalArray<T>() -> [T]? {
        let array: [T]? = self as? [T]
        return array
    }
}

public func safeArray<T>(_ array: [T]?) -> [T] {
    return array ?? []
}
