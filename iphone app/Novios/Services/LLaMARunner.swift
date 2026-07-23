import Foundation

public class LLaMARunner {
    public static let shared = LLaMARunner()
    public private(set) var isLoaded = false

    private init() {}

    public func loadModel(path: String) -> Bool { false }

    public func generate(prompt: String, maxTokens: Int = 256) -> String { "" }

    public func unloadModel() { isLoaded = false }
}
