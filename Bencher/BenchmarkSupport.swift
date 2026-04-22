import Foundation
#if canImport(Metal)
import Metal
#endif

enum BenchmarkMetricKind: String, Codable, CaseIterable {
    case singleCore
    case multiCore
    case memory
    case ssd
    case graphics
}

struct BenchmarkRawMetrics: Codable, Equatable {
    let singleCore: Double
    let multiCore: Double
    let memory: Double
    let memoryThroughputMBps: Double
    let ssd: Double
    let ssdCombinedMBps: Double
    let ssdReadMBps: Double
    let ssdWriteMBps: Double
    let graphics: Double
}

enum BenchmarkReliability: String, Codable {
    case good = "Good"
    case caution = "Caution"
    case invalid = "Needs Rerun"
}

struct BenchmarkValidationSummary: Codable, Equatable {
    let reliability: BenchmarkReliability
    let messages: [String]

    var shouldSave: Bool {
        reliability != .invalid
    }

    var primaryMessage: String? {
        messages.first
    }
}

enum BenchmarkScoreCalculator {
    private static let factors: [BenchmarkMetricKind: Double] = [
        .singleCore: 1.0,
        .multiCore: 0.85,
        .memory: 1.0,
        .ssd: 0.45,
        .graphics: 0.14
    ]

    private static let weights: [BenchmarkMetricKind: Double] = [
        .singleCore: 0.20,
        .multiCore: 0.25,
        .memory: 0.20,
        .ssd: 0.15,
        .graphics: 0.20
    ]

    static func calibratedScore(metric: BenchmarkMetricKind, rawValue: Double) -> Double {
        let factor = factors[metric] ?? 1.0
        return max((rawValue * factor).rounded(), 0)
    }

    static func calibratedScores(from rawMetrics: BenchmarkRawMetrics) -> [BenchmarkMetricKind: Double] {
        [
            .singleCore: calibratedScore(metric: .singleCore, rawValue: rawMetrics.singleCore),
            .multiCore: calibratedScore(metric: .multiCore, rawValue: rawMetrics.multiCore),
            .memory: calibratedScore(metric: .memory, rawValue: rawMetrics.memory),
            .ssd: calibratedScore(metric: .ssd, rawValue: rawMetrics.ssd),
            .graphics: calibratedScore(metric: .graphics, rawValue: rawMetrics.graphics)
        ]
    }

    static func overallScore(from scores: [BenchmarkMetricKind: Double]) -> Double {
        let baseline = 1000.0
        let normalized = BenchmarkMetricKind.allCases.reduce(0.0) { partial, metric in
            let score = scores[metric] ?? 0
            let weight = weights[metric] ?? 0
            return partial + ((score / baseline) * weight)
        }
        return (normalized * baseline).rounded()
    }
}

enum BenchmarkValidator {
    static func validate(
        rawMetrics: BenchmarkRawMetrics,
        intensity: String,
        graphicsBackend: String,
        thermalState: Int
    ) -> BenchmarkValidationSummary {
        var messages: [String] = []
        var reliability: BenchmarkReliability = .good

        let rawValues = [
            rawMetrics.singleCore,
            rawMetrics.multiCore,
            rawMetrics.memory,
            rawMetrics.memoryThroughputMBps,
            rawMetrics.ssd,
            rawMetrics.ssdCombinedMBps,
            rawMetrics.ssdReadMBps,
            rawMetrics.ssdWriteMBps,
            rawMetrics.graphics
        ]

        if rawValues.contains(where: { !$0.isFinite || $0 <= 0 }) {
            return BenchmarkValidationSummary(
                reliability: .invalid,
                messages: ["This run did not finish cleanly, so Bencher did not save it. Let the device settle for a moment and try again."]
            )
        }

        if rawMetrics.singleCore > 25_000
            || rawMetrics.multiCore > 140_000
            || rawMetrics.memoryThroughputMBps > 250_000
            || rawMetrics.ssdCombinedMBps > 50_000
            || rawMetrics.graphics > 250_000 {
            return BenchmarkValidationSummary(
                reliability: .invalid,
                messages: ["This result landed far outside Bencher's normal range, so it was skipped instead of being saved."]
            )
        }

        if rawMetrics.multiCore < rawMetrics.singleCore * 1.05 {
            reliability = .caution
            messages.append("Multi-core performance came in unusually close to the single-core run, so this result is worth double-checking.")
        }

        if rawMetrics.multiCore > rawMetrics.singleCore * 32 {
            reliability = .caution
            messages.append("Multi-core performance jumped much higher than expected, so this result is best treated with caution.")
        }

        if rawMetrics.graphics < 50 {
            reliability = .caution
            messages.append("The graphics run came in lower than expected, which can happen if the graphics test did not settle properly.")
        }

        if thermalState >= 2 {
            reliability = .caution
            messages.append("Your device was running warm during this benchmark, so some scores may be lower than usual.")
        }

        if intensity != "Balanced" {
            reliability = .caution
            messages.append("This run used \(intensity) mode, so it does not compare as fairly with Bencher's usual side-by-side comparisons.")
        }

        if graphicsBackend != "Metal" {
            reliability = .caution
            messages.append("This run used \(graphicsBackend) for graphics, so it may not compare perfectly with Metal results.")
        }

        return BenchmarkValidationSummary(reliability: reliability, messages: messages)
    }
}

#if canImport(Metal)
enum BencherGraphicsRuntime {
    private static let availabilityKey = "bencher.graphics.metal.available"
    private static let lastCheckedKey = "bencher.graphics.metal.lastChecked"

    static let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    kernel void bencherGraphics(
        device float4 *output [[buffer(0)]],
        constant uint &iterationCount [[buffer(1)]],
        constant uint &seed [[buffer(2)]],
        uint gid [[thread_position_in_grid]]
    ) {
        float base = float(gid + 1) * 0.00003125f + float(seed) * 0.013f;
        float4 value = float4(base, base * 1.31f, base * 1.73f, base * 2.11f);

        for (uint iteration = 0; iteration < iterationCount; ++iteration) {
            float4 mixValue = float4(0.71f, 1.13f, 1.57f, 1.91f) + float4(iteration) * 0.00017f;
            value = sin(value * mixValue + float4(0.17f, 0.29f, 0.37f, 0.43f));
            value += cos(value.yzwx * 0.73f + float4(iteration) * 0.00011f);
            value = sqrt(fabs(value) + float4(0.0001f));
        }

        output[gid] = value;
    }
    """

    static var recordedAvailability: Bool? {
        guard UserDefaults.standard.object(forKey: availabilityKey) != nil else { return nil }
        return UserDefaults.standard.bool(forKey: availabilityKey)
    }

    static var lastCheckedDate: Date? {
        UserDefaults.standard.object(forKey: lastCheckedKey) as? Date
    }

    static func performStartupSelfCheck() {
        DispatchQueue.global(qos: .utility).async {
            let available = compileSelfCheck()
            recordAvailability(available)
        }
    }

    static func recordAvailability(_ available: Bool) {
        UserDefaults.standard.set(available, forKey: availabilityKey)
        UserDefaults.standard.set(Date(), forKey: lastCheckedKey)
    }

    private static func compileSelfCheck() -> Bool {
        guard let device = preferredMetalDevice() else { return false }

        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            return library.makeFunction(name: "bencherGraphics") != nil
        } catch {
            return false
        }
    }

    private static func preferredMetalDevice() -> MTLDevice? {
        #if os(macOS)
        let devices = MTLCopyAllDevices()
        return devices.first(where: { !$0.isRemovable }) ?? devices.first ?? MTLCreateSystemDefaultDevice()
        #else
        return MTLCreateSystemDefaultDevice()
        #endif
    }
}
#endif
