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
    func leaderboardRankingUsesTopTenAndNewestTieBreak() async throws {
        let baseDate = Date(timeIntervalSince1970: 1_000)
        var results: [BenchmarkResult] = []
        for index in 0..<12 {
            let score = index == 2 ? 900.0 : Double(700 + index)
            results.append(
                makeResult(
                    id: UUID(),
                    deviceName: "iPhone 17 Pro Max",
                    intensity: "Balanced",
                    graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
                    timestamp: baseDate.addingTimeInterval(Double(index)),
                    overallScore: score
                )
            )
        }
        let newestTiedResult = makeResult(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            deviceName: "iPhone 17 Pro Max",
            intensity: "Balanced",
            graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
            timestamp: baseDate.addingTimeInterval(500),
            overallScore: 900
        )

        let ranked = LeaderboardRanking.topResults(from: results + [newestTiedResult])

        #expect(ranked.count == 10)
        #expect(ranked.first?.id == newestTiedResult.id)
        #expect(ranked.dropFirst().first?.overallScore == 900)
    }

    @Test
    func leaderboardFiltersByDeviceModeAndGraphicsBackend() async throws {
        let currentDevice = "Adam's iPad"
        let currentBalancedMetal = makeResult(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            deviceName: currentDevice,
            intensity: "Balanced",
            graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
            timestamp: Date(timeIntervalSince1970: 100),
            overallScore: 810
        )
        let otherDevice = makeResult(
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            deviceName: "Mac mini",
            intensity: "Balanced",
            graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
            timestamp: Date(timeIntervalSince1970: 200),
            overallScore: 900
        )
        let extremeLegacy = makeResult(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            deviceName: currentDevice,
            intensity: "Extreme",
            graphicsBackend: GraphicsBenchmarkBackend.legacy.rawValue,
            timestamp: Date(timeIntervalSince1970: 300),
            overallScore: 950
        )
        let results = [currentBalancedMetal, otherDevice, extremeLegacy]

        #expect(LeaderboardRanking.topResults(from: results, filter: .currentDevice, currentDeviceName: currentDevice).map(\.id) == [extremeLegacy.id, currentBalancedMetal.id])
        #expect(LeaderboardRanking.topResults(from: results, filter: .balancedOnly, currentDeviceName: currentDevice).map(\.id) == [otherDevice.id, currentBalancedMetal.id])
        #expect(LeaderboardRanking.topResults(from: results, filter: .metalOnly, currentDeviceName: currentDevice).map(\.id) == [otherDevice.id, currentBalancedMetal.id])
    }

    @Test
    func cancellationStateBrieflyReportsCancelledThenReturnsReady() async throws {
        #expect(BenchmarkCancellationState.cancelled.progressMessage == "Benchmark cancelled.")
        #expect(BenchmarkCancellationState.cancelled.overallProgress == 0.0)
        #expect(BenchmarkCancellationState.cancelled.taskProgress == 0.0)
        #expect(BenchmarkCancellationState.ready.progressMessage == "Ready to benchmark!")
        #expect(BenchmarkCancellationState.ready.overallProgress == 0.0)
        #expect(BenchmarkCancellationState.ready.taskProgress == 0.0)
    }

    @Test
    func csvExportRoundTripsImportableResults() async throws {
        let original = makeResult(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            deviceName: "Adam's iPhone, Test Edition",
            intensity: "Balanced",
            graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            overallScore: 901
        )

        let data = BenchmarkHistoryCSVDocument.exportData(for: [original])
        let imported = try BenchmarkHistoryCSVDocument.parseCSV(data)

        #expect(imported.count == 1)
        #expect(imported.first?.id == original.id)
        #expect(imported.first?.deviceName == original.deviceName)
        #expect(imported.first?.graphicsBackend == GraphicsBenchmarkBackend.metal.rawValue)
        #expect(imported.first?.overallScore == 901)
    }

    @Test
    func dockPreferenceRulesKeepDashboardAndBenchmarkExpanded() async throws {
        #expect(TabBarDockPreference.usesMinimisedBar(for: TabBarDockPreference.automatic.rawValue, selectedTab: "dashboard") == false)
        #expect(TabBarDockPreference.usesMinimisedBar(for: TabBarDockPreference.automatic.rawValue, selectedTab: "benchmark") == false)
        #expect(TabBarDockPreference.usesMinimisedBar(for: TabBarDockPreference.automatic.rawValue, selectedTab: "history"))
        #expect(TabBarDockPreference.usesMinimisedBar(for: TabBarDockPreference.alwaysShow.rawValue, selectedTab: "history") == false)
        #expect(TabBarDockPreference.usesMinimisedBar(for: TabBarDockPreference.hideOnScroll.rawValue, selectedTab: "benchmark") == false)
        #expect(TabBarDockPreference.usesMinimisedBar(for: TabBarDockPreference.hideOnScroll.rawValue, selectedTab: "settings"))
    }

    @Test
    func storageDiagnosticsSummariseSavedHistory() async throws {
        let result = makeResult(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            deviceName: "Diagnostics Device",
            intensity: "Balanced",
            graphicsBackend: GraphicsBenchmarkBackend.metal.rawValue,
            timestamp: Date(timeIntervalSince1970: 2_000)
        )

        UserDefaults.standard.set(false, forKey: "icloudHistorySyncEnabled")
        BenchmarkStorage.save([result])
        let diagnostics = BenchmarkStorage.diagnostics()

        #expect(diagnostics.activeResultCount >= 1)
        #expect(diagnostics.localStorageBytes >= 0)
        #expect(diagnostics.formattedStorageSize.isEmpty == false)
        #expect(diagnostics.syncStatusText.isEmpty == false)
    }

    @Test
    func releaseNotesExposeCurrentBuildEntry() async throws {
        #expect(BencherReleaseNotesEntries.isEmpty == false)
        #expect(BencherReleaseNotesEntries.first?.version == "V1.50")
        #expect(BencherReleaseNotesEntries.filter { $0.releaseDate == "Current Build" }.count == 1)
    }

    @Test
    func updateSearchFindsVersionsAndDetails() async throws {
        let versionMatches = BencherReleaseNotesEntries.rankedUpdateSearchResults(for: "1.50")
        let feedbackMatches = BencherReleaseNotesEntries.rankedUpdateSearchResults(for: "feedback icon")
        let graphicsMatches = BencherReleaseNotesEntries.rankedUpdateSearchResults(for: "mac cloud graphics")

        #expect(versionMatches.first?.version == "V1.50")
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
        timestamp: Date,
        overallScore: Double = 790
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
            overallScore: overallScore,
            timestamp: timestamp,
            thermalState: 0,
            wasConnectedToPower: false,
            reliability: .good,
            validationMessages: []
        )
    }
}
