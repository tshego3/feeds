import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Fetches available AI models from the HuggingFace API with bundled fallback.
struct ModelRegistryService: Sendable {

    private static let hfAPIURL = "https://huggingface.co/api/models?author=mlx-community&pipeline_tag=text-generation&sort=downloads&direction=-1&limit=50"

    /// Fetches models: tries HuggingFace API first, falls back to bundled ai_models.json.
    static func fetchModels() async -> [AIModelInfo] {
        if let remote = try? await fetchRemoteModels(), !remote.isEmpty {
            return remote
        }
        return loadBundledModels()
    }

    // MARK: - Remote (HuggingFace API)

    private static func fetchRemoteModels() async throws -> [AIModelInfo] {
        guard let url = URL(string: hfAPIURL) else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else { return [] }

        let entries = try JSONDecoder().decode([HFModelEntry].self, from: data)
        return entries
            .filter { isSmallQuantizedModel($0) }
            .prefix(15)
            .map { mapToModelInfo($0) }
    }

    private static func isSmallQuantizedModel(_ entry: HFModelEntry) -> Bool {
        let id = entry.modelId.lowercased()
        let hasQuantization = id.contains("4bit") || id.contains("qat") || id.contains("3bit")
        let isLargeModel = id.contains("7b") || id.contains("8b") || id.contains("9b") ||
            id.contains("14b") || id.contains("27b") || id.contains("30b") || id.contains("70b")
        let isMoE = id.contains("moe") || id.contains("a3b")
        return hasQuantization && !isLargeModel && !isMoE
    }

    private static func mapToModelInfo(_ entry: HFModelEntry) -> AIModelInfo {
        let rawName = entry.modelId.replacingOccurrences(of: "mlx-community/", with: "")
        let displayName = rawName
            .replacingOccurrences(of: "-4bit", with: "")
            .replacingOccurrences(of: "-3bit", with: "")
            .replacingOccurrences(of: "-qat", with: "")
            .replacingOccurrences(of: "-Instruct", with: "")
            .replacingOccurrences(of: "-instruct", with: "")
            .replacingOccurrences(of: "-it-", with: "-")
            .replacingOccurrences(of: "-it", with: "")
            .replacingOccurrences(of: "-hf", with: "")
            .replacingOccurrences(of: "-MLX", with: "")

        let sizeLabel = estimateSize(from: entry.modelId.lowercased())
        let safeID = rawName
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: ".", with: "_")

        return AIModelInfo(
            id: safeID,
            name: displayName,
            description: "\(entry.downloads ?? 0) downloads",
            sizeLabel: sizeLabel,
            huggingFaceID: entry.modelId
        )
    }

    private static func estimateSize(from id: String) -> String {
        if id.contains("0.3b") || id.contains("0.5b") { return "~0.3 GB" }
        if id.contains("0.6b") { return "~0.4 GB" }
        if id.contains("130m") || id.contains("135m") { return "~0.1 GB" }
        if id.contains("1.2b") || id.contains("1.5b") { return "~0.9 GB" }
        if id.contains("1.7b") { return "~1.0 GB" }
        if id.contains("1b") { return "~0.7 GB" }
        if id.contains("2b") { return "~1.2 GB" }
        if id.contains("3b") { return "~1.8 GB" }
        if id.contains("4b") { return "~2.4 GB" }
        return "~1.0 GB"
    }

    // MARK: - Bundled Fallback

    static func loadBundledModels() -> [AIModelInfo] {
        guard let url = Bundle.main.url(forResource: "ai_models", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let models = try? JSONDecoder().decode([AIModelInfo].self, from: data) else {
            return AIModelInfo.fallback
        }
        return models
    }
}

// MARK: - HuggingFace API Response

private struct HFModelEntry: Decodable {
    let modelId: String
    let downloads: Int?

    enum CodingKeys: String, CodingKey {
        case modelId = "id"
        case downloads
    }
}
