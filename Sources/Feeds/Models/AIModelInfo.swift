import Foundation

/// Metadata for an on-device AI model available for download.
struct AIModelInfo: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let description: String
    let sizeLabel: String
    let huggingFaceID: String

    /// Compile-time fallback when bundled JSON and remote fetch both fail.
    static let fallback: [AIModelInfo] = [
        AIModelInfo(id: "gemma3_1B_qat_4bit", name: "Gemma 3 1B",
                    description: "Google's compact model. Fast and efficient.",
                    sizeLabel: "~0.6 GB", huggingFaceID: "mlx-community/gemma-3-1b-it-qat-4bit"),
        AIModelInfo(id: "llama3_2_1B_4bit", name: "Llama 3.2 1B",
                    description: "Meta's smallest Llama. Fast summaries.",
                    sizeLabel: "~0.7 GB", huggingFaceID: "mlx-community/Llama-3.2-1B-Instruct-4bit"),
        AIModelInfo(id: "qwen3_0_6b_4bit", name: "Qwen 3 0.6B",
                    description: "Ultra-small. Fastest inference speed.",
                    sizeLabel: "~0.4 GB", huggingFaceID: "mlx-community/Qwen3-0.6B-4bit"),
    ]
}
