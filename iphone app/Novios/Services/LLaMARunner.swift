import Foundation

public class LLaMARunner {
    public static let shared = LLaMARunner()

    public private(set) var isAvailable = false
    public private(set) var isLoaded = false

    private init() {}

    public func loadModel(path: String) -> Bool {
        return false
    }

    public func generate(prompt: String, maxTokens: Int = 256) -> String {
        return ""
    }

    public func unloadModel() {
        isLoaded = false
    }
}
