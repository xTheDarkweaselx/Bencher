import Foundation
import Testing
@testable import Bencher

struct BencherTests {
    @Test
    func scoreCalculatorSeparatesRawAndDisplayScores() async throws {
        let rawMetrics = BenchmarkRawMetrics(
            singleCore: 640,
            multiCore: 1_440,
            memory: 180,
            memoryThroughputMBps: 18_000,
            ssd: 2_000,
            ssdCombinedMBps: 2_000,
            ssdReadMBps: 2_200,
            ssdWriteMBps: 1_800,
            graphics: 6_000
        )

        let scores = BenchmarkScoreCalculator.calibratedScores(from: rawMetrics)

        #expect(scores[.singleCore] == 640)
        #expect(scores[.multiCore] == 1_224)
        #expect(scores[.ssd] == 900)
        #expect(scores[.graphics] == 840)
        #expect(BenchmarkScoreCalculator.overallScore(from: scores) > 0)
    }

    @Test
    func validatorRejectsClearlyBrokenRuns() async throws {
        let brokenMetrics = BenchmarkRawMetrics(
            singleCore: 0,
            multiCore: 10_000,
            memory: 100,
            memoryThroughputMBps: 12_000,
            ssd: 1_000,
            ssdCombinedMBps: 1_000,
            ssdReadMBps: 1_100,
            ssdWriteMBps: 900,
            graphics: 500
        )

        let summary = BenchmarkValidator.validate(
            rawMetrics: brokenMetrics,
            intensity: "Balanced",
            graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
            thermalState: 0
        )

        #expect(summary.reliability == .invalid)
        #expect(summary.shouldSave == false)
        #expect(summary.messages.isEmpty == false)
    }

    @Test
    func validatorFlagsLessComparableRuns() async throws {
        let rawMetrics = BenchmarkRawMetrics(
            singleCore: 650,
            multiCore: 900,
            memory: 160,
            memoryThroughputMBps: 14_000,
            ssd: 1_800,
            ssdCombinedMBps: 1_800,
            ssdReadMBps: 2_000,
            ssdWriteMBps: 1_600,
            graphics: 1_200
        )

        let summary = BenchmarkValidator.validate(
            rawMetrics: rawMetrics,
            intensity: "Extreme",
            graphicsBackend: GraphicsBenchmarkBackend.legacy.rawValue,
            thermalState: 2
        )

        #expect(summary.reliability == .caution)
        #expect(summary.shouldSave)
        #expect(summary.messages.count >= 2)
    }

    @Test
    func comparableBaselineMatchesDeviceModeAndGraphicsMethod() async throws {
        let baseDate = Date(timeIntervalSince1970: 1_000)
        let olderMatch = makeResult(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            deviceName: "iPhone 17 Pro Max",
            intensity: "Balanced",
            graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
            timestamp: baseDate
        )
        let wrongMode = makeResult(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            deviceName: "iPhone 17 Pro Max",
            intensity: "Extreme",
            graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
            timestamp: baseDate.addingTimeInterval(100)
        )
        let latest = makeResult(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            deviceName: "iPhone 17 Pro Max",
            intensity: "Balanced",
            graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
            timestamp: baseDate.addingTimeInterval(200)
        )

        let baseline = comparableBenchmarkBaseline(for: latest, within: [olderMatch, wrongMode, latest])

        #expect(baseline?.id == olderMatch.id)
    }

    @Test
    func mergeForImportKeepsNewestDuplicate() async throws {
        let id = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let oldResult = makeResult(
            id: id,
            deviceName: "iPad mini",
            intensity: "Balanced",
            graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
            timestamp: Date(timeIntervalSince1970: 100)
        )
        let newResult = makeResult(
            id: id,
            deviceName: "iPad mini",
            intensity: "Balanced",
            graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
            timestamp: Date(timeIntervalSince1970: 200)
        )

        let merged = BenchmarkStorage.mergeForImport(existing: [oldResult], imported: [newResult])

        #expect(merged.count == 1)
        #expect(merged.first?.timestamp == newResult.timestamp)
    }

    @Test
    func releaseNotesExposeCurrentBuildEntry() async throws {
        #expect(BencherReleaseNotesEntries.isEmpty == false)
        #expect(BencherReleaseNotesEntries.first?.version == "V1.10")
        #expect(BencherReleaseNotesEntries.filter { $0.releaseDate == "Current Build" }.count == 1)
    }

    @Test
    func updateSearchFindsVersionsAndDetails() async throws {
        let versionMatches = BencherReleaseNotesEntries.rankedUpdateSearchResults(for: "1.10")
        let feedbackMatches = BencherReleaseNotesEntries.rankedUpdateSearchResults(for: "feedback icon")
        let graphicsMatches = BencherReleaseNotesEntries.rankedUpdateSearchResults(for: "mac cloud graphics")

        #expect(versionMatches.first?.version == "V1.10")
        #expect(feedbackMatches.contains { $0.version == "V1.01" })
        #expect(graphicsMatches.first?.version == "V1.02")
    }

    @Test
    func updateSearchRequiresAllTypedKeywords() async throws {
        let matches = BencherReleaseNotesEntries.rankedUpdateSearchResults(for: "iphone portrait filters")
        let unrelatedMatches = BencherReleaseNotesEntries.rankedUpdateSearchResults(for: "iphone opencl encryption")

        #expect(matches.first?.version == "V0.99")
        #expect(unrelatedMatches.isEmpty)
    }

    private func makeResult(
        id: UUID,
        deviceName: String,
        intensity: String,
        graphicsBackend: String,
        timestamp: Date
    ) -> BenchmarkResult {
        BenchmarkResult(
            id: id,
            sessionID: id,
            deviceName: deviceName,
            benchmarkIntensity: intensity,
            singleCoreScore: 650,
            cpuScore: 1_250,
            memoryScore: 160,
            memoryRawThroughputMBps: 14_000,
            ssdScore: 900,
            ssdRawCombinedMBps: 2_100,
            ssdRawReadMBps: 2_300,
            ssdRawWriteMBps: 1_900,
            graphicsBackend: graphicsBackend,
            graphicsScore: 840,
            rawSingleCoreScore: 650,
            rawMultiCoreScore: 1_470,
            rawMemoryScore: 160,
            rawSSDScore: 2_000,
            rawGraphicsScore: 6_000,
            overallScore: 790,
            timestamp: timestamp,
            thermalState: 0,
            wasConnectedToPower: false,
            reliability: .good,
            validationMessages: []
        )
    }
}
