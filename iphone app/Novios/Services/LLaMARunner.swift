import Foundation

public class LLaMARunner {
    public static let shared = LLaMARunner()

    public private(set) var isAvailable = false
    public private(set) var isLoaded = false

    private init() {
        isAvailable = checkAvailability()
    }

    private func checkAvailability() -> Bool {
        dlopen("libllama.dylib", RTLD_NOLOAD) != nil ||
        dlopen("llama.framework/llama", RTLD_NOLOAD) != nil
    }

    public func loadModel(path: String) -> Bool {
        guard isAvailable, !isLoaded else { return isLoaded }
        return false
    }

    public func generate(prompt: String, maxTokens: Int = 256) -> String {
        guard isLoaded else { return "" }
        return ""
    }

    public func unloadModel() {
        isLoaded = false
    }
}
