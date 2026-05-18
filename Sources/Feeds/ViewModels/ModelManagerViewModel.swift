import Foundation
#if canImport(MLXLLM)
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers
#endif

/// Manages on-device AI model lifecycle: download, activation, switching, and inference.
// TODO: Android local AI — integrate llama.cpp (via C FFI) or ONNX Runtime to enable
//       on-device inference on non-Apple platforms. Steps:
//       1. Add llama.cpp as a C dependency in Package.swift (conditionally for Android)
//       2. Create an `LLMProvider` protocol abstracting model load + inference
//       3. Implement `MLXProvider` (Apple) and `LlamaCppProvider` (Android)
//       4. Swap provider in init based on platform availability
//       5. Host quantized GGUF models on HuggingFace for Android downloads
@MainActor
class ModelManagerViewModel: ObservableObject {

    private let defaults: UserDefaults

    @Published var availableModels: [AIModelInfo] = []
    @Published private(set) var downloadedModelIDs: Set<String>
    @Published var activeModelID: String?
    @Published private(set) var isDownloading: Bool = false
    @Published private(set) var downloadingModelID: String?
    @Published private(set) var downloadProgress: Double = 0
    @Published private(set) var isModelLoaded: Bool = false
    @Published private(set) var isGenerating: Bool = false
    @Published private(set) var errorMessage: String?

    #if canImport(MLXLLM) && !targetEnvironment(simulator)
    private var modelContainer: ModelContainer?
    #endif
    private var loadedModelID: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.stringArray(forKey: "downloadedModelIDs") ?? []
        self.downloadedModelIDs = Set(saved)
        self.activeModelID = defaults.string(forKey: "activeModelID")
        self.availableModels = ModelRegistryService.loadBundledModels()
    }

    var activeModel: AIModelInfo? {
        guard let id = activeModelID else { return nil }
        return availableModels.first { $0.id == id }
    }

    var isMLXAvailable: Bool {
        #if canImport(MLXLLM) && !targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Model List

    func loadAvailableModels() async {
        let models = await ModelRegistryService.fetchModels()
        guard !models.isEmpty else { return }
        availableModels = models
    }

    // MARK: - Download & Activate

    func downloadAndActivate(_ model: AIModelInfo) async {
        #if canImport(MLXLLM) && !targetEnvironment(simulator)
        guard !isDownloading else { return }
        isDownloading = true
        downloadingModelID = model.id
        downloadProgress = 0
        errorMessage = nil

        do {
            let config = resolveConfiguration(for: model)
            modelContainer = try await loadModelContainer(
                from: #hubDownloader(),
                using: #huggingFaceTokenizerLoader(),
                configuration: config,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        self?.downloadProgress = progress.fractionCompleted
                    }
                }
            )

            loadedModelID = model.id
            isModelLoaded = true
            activeModelID = model.id
            downloadedModelIDs.insert(model.id)
            persistState()
        } catch is URLError {
            errorMessage = "Network error. Please check your connection and try again."
            isModelLoaded = false
        } catch {
            let desc = error.localizedDescription.lowercased()
            if desc.contains("disk") || desc.contains("space") || desc.contains("no such file") {
                errorMessage = "Not enough storage to download this model. Free up space and try again."
            } else if desc.contains("cancelled") || desc.contains("canceled") {
                errorMessage = nil
            } else {
                errorMessage = "Failed to download model. Please try again later."
            }
            isModelLoaded = false
        }

        isDownloading = false
        downloadingModelID = nil
        #else
        errorMessage = "AI models require a physical device. The simulator does not support on-device inference."
        #endif
    }

    func activateModel(_ model: AIModelInfo) async {
        guard model.id != loadedModelID else { return }
        await downloadAndActivate(model)
    }

    func deactivateModel() {
        #if canImport(MLXLLM) && !targetEnvironment(simulator)
        modelContainer = nil
        #endif
        loadedModelID = nil
        isModelLoaded = false
        activeModelID = nil
        defaults.removeObject(forKey: "activeModelID")
    }

    func deleteModel(_ model: AIModelInfo) {
        if activeModelID == model.id {
            deactivateModel()
        }
        deleteModelFiles(model)
        downloadedModelIDs.remove(model.id)
        persistState()
    }

    // MARK: - Inference

    func generateSummary(for text: String) async -> String? {
        #if canImport(MLXLLM) && !targetEnvironment(simulator)
        guard let container = modelContainer else {
            errorMessage = "No model loaded."
            return nil
        }
        guard !isGenerating else { return nil }
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let trimmedText = String(text.prefix(2000))
            let prompt = "Summarize the following article in 2-3 concise sentences:\n\n\(trimmedText)"

            var params = GenerateParameters()
            params.maxTokens = 256
            let session = ChatSession(container, generateParameters: params)
            return try await session.respond(to: prompt)
        } catch {
            errorMessage = "Summary generation failed. Please try again."
            return nil
        }
        #else
        errorMessage = "AI models require a physical device. The simulator does not support on-device inference."
        return nil
        #endif
    }

    // MARK: - Load on Launch

    func restoreActiveModel() async {
        await loadAvailableModels()
        guard let id = activeModelID,
              downloadedModelIDs.contains(id),
              let model = availableModels.first(where: { $0.id == id }) else { return }
        await downloadAndActivate(model)
    }

    // MARK: - Private

    private func persistState() {
        defaults.set(Array(downloadedModelIDs), forKey: "downloadedModelIDs")
        if let active = activeModelID {
            defaults.set(active, forKey: "activeModelID")
        }
    }

    private func deleteModelFiles(_ model: AIModelInfo) {
        let cacheDirs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        guard let cacheDir = cacheDirs.first else { return }
        let hubDir = cacheDir.appendingPathComponent("huggingface/hub")
        let dirName = "models--\(model.huggingFaceID.replacingOccurrences(of: "/", with: "--"))"
        let modelDir = hubDir.appendingPathComponent(dirName)
        try? FileManager.default.removeItem(at: modelDir)
    }

    #if canImport(MLXLLM) && !targetEnvironment(simulator)
    private func resolveConfiguration(for model: AIModelInfo) -> ModelConfiguration {
        // Prefer registry entries (include extra EOS tokens and tested configs)
        switch model.huggingFaceID {
        case "mlx-community/gemma-3-1b-it-qat-4bit": return LLMRegistry.gemma3_1B_qat_4bit
        case "mlx-community/Qwen3-0.6B-4bit": return LLMRegistry.qwen3_0_6b_4bit
        case "mlx-community/Qwen3-1.7B-4bit": return LLMRegistry.qwen3_1_7b_4bit
        case "mlx-community/Llama-3.2-1B-Instruct-4bit": return LLMRegistry.llama3_2_1B_4bit
        case "mlx-community/Llama-3.2-3B-Instruct-4bit": return LLMRegistry.llama3_2_3B_4bit
        case "mlx-community/SmolLM3-3B-4bit": return LLMRegistry.smollm3_3b_4bit
        case "mlx-community/gemma-3n-E2B-it-lm-4bit": return LLMRegistry.gemma3n_E2B_it_lm_4bit
        case "mlx-community/Qwen2.5-1.5B-Instruct-4bit": return LLMRegistry.qwen2_5_1_5b
        // Dynamically discovered models: use HuggingFace ID directly
        default: return ModelConfiguration(id: model.huggingFaceID)
        }
    }
    #endif
}
