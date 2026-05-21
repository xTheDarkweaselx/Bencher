import CloudKit
import Foundation
import SwiftUI

struct CommunityBenchmarkResult: Identifiable, Equatable {
    let id: String
    let sourceResultID: String
    let deviceName: String
    let platform: String
    let osMajorVersion: Int
    let osMinorVersion: Int
    let appVersion: String
    let benchmarkIntensity: String
    let graphicsBackend: String
    let singleCoreScore: Double
    let multiCoreScore: Double
    let memoryScore: Double
    let ssdScore: Double
    let graphicsScore: Double
    let overallScore: Double
    let thermalState: Int
    let wasConnectedToPower: Bool?
    let reliability: String
    let validationMessageCount: Int
    let moderationState: String
    let isExcludedFromCommunityStats: Bool
    let uploadedAt: Date
    let scoreSchemaVersion: Int

    init?(record: CKRecord) {
        guard let schemaVersion = record[CommunityBenchmarkRecord.Field.schemaVersion] as? Int,
              schemaVersion == CommunityBenchmarkRecord.schemaVersion,
              let sourceResultID = record[CommunityBenchmarkRecord.Field.sourceResultID] as? String,
              let deviceName = record[CommunityBenchmarkRecord.Field.deviceName] as? String,
              let platform = record[CommunityBenchmarkRecord.Field.platform] as? String,
              let osMajorVersion = record[CommunityBenchmarkRecord.Field.osMajorVersion] as? Int,
              let osMinorVersion = record[CommunityBenchmarkRecord.Field.osMinorVersion] as? Int,
              let appVersion = record[CommunityBenchmarkRecord.Field.appVersion] as? String,
              let benchmarkIntensity = record[CommunityBenchmarkRecord.Field.benchmarkIntensity] as? String,
              let graphicsBackend = record[CommunityBenchmarkRecord.Field.graphicsBackend] as? String,
              let singleCoreScore = record[CommunityBenchmarkRecord.Field.singleCoreScore] as? Double,
              let multiCoreScore = record[CommunityBenchmarkRecord.Field.multiCoreScore] as? Double,
              let memoryScore = record[CommunityBenchmarkRecord.Field.memoryScore] as? Double,
              let ssdScore = record[CommunityBenchmarkRecord.Field.ssdScore] as? Double,
              let graphicsScore = record[CommunityBenchmarkRecord.Field.graphicsScore] as? Double,
              let overallScore = record[CommunityBenchmarkRecord.Field.overallScore] as? Double,
              let thermalState = record[CommunityBenchmarkRecord.Field.thermalState] as? Int,
              let uploadedAt = record[CommunityBenchmarkRecord.Field.uploadedAt] as? Date,
              let scoreSchemaVersion = record[CommunityBenchmarkRecord.Field.scoreSchemaVersion] as? Int else {
            return nil
        }

        let powerNumber = record[CommunityBenchmarkRecord.Field.wasConnectedToPower] as? Int
        self.id = record.recordID.recordName
        self.sourceResultID = sourceResultID
        self.deviceName = deviceName
        self.platform = platform
        self.osMajorVersion = osMajorVersion
        self.osMinorVersion = osMinorVersion
        self.appVersion = appVersion
        self.benchmarkIntensity = benchmarkIntensity
        self.graphicsBackend = graphicsBackend
        self.singleCoreScore = singleCoreScore
        self.multiCoreScore = multiCoreScore
        self.memoryScore = memoryScore
        self.ssdScore = ssdScore
        self.graphicsScore = graphicsScore
        self.overallScore = overallScore
        self.thermalState = thermalState
        self.wasConnectedToPower = powerNumber.map { $0 == 1 }
        self.reliability = record[CommunityBenchmarkRecord.Field.reliability] as? String ?? BenchmarkReliability.good.rawValue
        self.validationMessageCount = record[CommunityBenchmarkRecord.Field.validationMessageCount] as? Int ?? 0
        self.moderationState = record[CommunityBenchmarkRecord.Field.moderationState] as? String ?? CommunityModerationState.active.rawValue
        self.isExcludedFromCommunityStats = (record[CommunityBenchmarkRecord.Field.isExcludedFromCommunityStats] as? Int ?? 0) == 1
        self.uploadedAt = uploadedAt
        self.scoreSchemaVersion = scoreSchemaVersion
    }

    var canContributeToAverages: Bool {
        moderationState == CommunityModerationState.active.rawValue && !isExcludedFromCommunityStats
    }
}

struct CommunityResultStatistics: Equatable {
    static let minimumStableSampleCount = 10

    let sampleCount: Int
    let filteredSampleCount: Int
    let q1: Double
    let median: Double
    let q3: Double
    let filteredAverage: Double
    let minimumStableSampleCount: Int

    var isStable: Bool {
        sampleCount >= minimumStableSampleCount
    }

    static func calculate(values: [Double], minimumStableSampleCount: Int = Self.minimumStableSampleCount) -> CommunityResultStatistics? {
        let sortedValues = values.filter(\.isFinite).sorted()
        guard !sortedValues.isEmpty else { return nil }

        let q1 = percentile(0.25, in: sortedValues)
        let median = percentile(0.5, in: sortedValues)
        let q3 = percentile(0.75, in: sortedValues)
        let iqr = q3 - q1
        let lowerBound = q1 - (1.5 * iqr)
        let upperBound = q3 + (1.5 * iqr)
        let filtered = sortedValues.filter { value in
            value >= lowerBound && value <= upperBound
        }
        let filteredAverage = filtered.reduce(0, +) / Double(filtered.count)

        return CommunityResultStatistics(
            sampleCount: sortedValues.count,
            filteredSampleCount: filtered.count,
            q1: q1,
            median: median,
            q3: q3,
            filteredAverage: filteredAverage,
            minimumStableSampleCount: minimumStableSampleCount
        )
    }

    private static func percentile(_ percentile: Double, in sortedValues: [Double]) -> Double {
        guard let first = sortedValues.first else { return 0 }
        guard sortedValues.count > 1 else { return first }

        let clamped = min(max(percentile, 0), 1)
        let position = clamped * Double(sortedValues.count - 1)
        let lowerIndex = Int(position.rounded(.down))
        let upperIndex = Int(position.rounded(.up))
        guard lowerIndex != upperIndex else { return sortedValues[lowerIndex] }

        let fraction = position - Double(lowerIndex)
        return sortedValues[lowerIndex] + ((sortedValues[upperIndex] - sortedValues[lowerIndex]) * fraction)
    }
}

struct CommunityResultGroup: Identifiable, Equatable {
    let deviceName: String
    let benchmarkIntensity: String
    let graphicsBackend: String
    let results: [CommunityBenchmarkResult]

    var id: String {
        "\(deviceName)|\(benchmarkIntensity)|\(graphicsBackend)"
    }

    var averageEligibleResults: [CommunityBenchmarkResult] {
        results.filter(\.canContributeToAverages)
    }

    var overallStatistics: CommunityResultStatistics? {
        CommunityResultStatistics.calculate(values: averageEligibleResults.map(\.overallScore))
    }

    func metricStatistics(for keyPath: KeyPath<CommunityBenchmarkResult, Double>) -> CommunityResultStatistics? {
        CommunityResultStatistics.calculate(values: averageEligibleResults.map { $0[keyPath: keyPath] })
    }

    var singleCoreStatistics: CommunityResultStatistics? { metricStatistics(for: \.singleCoreScore) }
    var multiCoreStatistics: CommunityResultStatistics? { metricStatistics(for: \.multiCoreScore) }
    var graphicsStatistics: CommunityResultStatistics? { metricStatistics(for: \.graphicsScore) }

    static func grouped(from results: [CommunityBenchmarkResult]) -> [CommunityResultGroup] {
        let buckets = Dictionary(grouping: results) { result in
            "\(result.deviceName)|\(result.benchmarkIntensity)|\(result.graphicsBackend)"
        }

        return buckets.values
            .map { groupedResults in
                let first = groupedResults[0]
                return CommunityResultGroup(
                    deviceName: first.deviceName,
                    benchmarkIntensity: first.benchmarkIntensity,
                    graphicsBackend: first.graphicsBackend,
                    results: groupedResults.sorted(by: { $0.uploadedAt > $1.uploadedAt })
                )
            }
            .sorted { lhs, rhs in
                let lhsMedian = lhs.overallStatistics?.median ?? 0
                let rhsMedian = rhs.overallStatistics?.median ?? 0
                if lhsMedian == rhsMedian {
                    return lhs.deviceName < rhs.deviceName
                }
                return lhsMedian > rhsMedian
            }
    }
}

enum CommunityUploadState: Equatable {
    case idle
    case checkingStatus
    case checkingAccount
    case uploading
    case uploaded
    case deleting
    case failed(String)
}

enum CommunityLeaderboardMode: String, CaseIterable, Identifiable {
    case averages = "Averages"
    case results = "Results"

    var id: String { rawValue }
}

enum CommunityModerationState: String {
    case active
    case hidden
    case flagged
}

struct CommunityBulkUploadSummary: Equatable {
    let uploadedCount: Int
    let skippedAlreadyUploadedCount: Int
    let skippedDueToCapCount: Int
    let failedCount: Int
    let averageEligibleCount: Int
    let excludedFromAveragesCount: Int
    let totalCount: Int
    let wasCancelled: Bool

    var message: String {
        var parts: [String] = []
        if wasCancelled {
            parts.append("Stopped at \(uploadedCount + skippedAlreadyUploadedCount + skippedDueToCapCount + failedCount) of \(totalCount)")
        }
        if uploadedCount > 0 {
            parts.append("Uploaded \(uploadedCount)")
        }
        if skippedAlreadyUploadedCount > 0 {
            parts.append("Skipped \(skippedAlreadyUploadedCount) already on iCloud")
        }
        if skippedDueToCapCount > 0 {
            parts.append("Skipped \(skippedDueToCapCount) over the per-device cap of \(CommunityResultsService.maxUploadsPerDeviceGroup)")
        }
        if failedCount > 0 {
            parts.append("\(failedCount) failed")
        }
        if averageEligibleCount > 0 {
            parts.append("\(averageEligibleCount) count toward averages")
        }
        if excludedFromAveragesCount > 0 {
            parts.append("\(excludedFromAveragesCount) shown individually only")
        }
        return parts.joined(separator: ". ") + "."
    }
}

enum CommunityBenchmarkRecord {
    static let recordType = "CommunityBenchmarkResult"
    static let schemaVersion = 1
    static let scoreSchemaVersion = 1

    static var containerIdentifier: String {
        "iCloud.\(bundleIdentifier)"
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Fusion-Studios.Bencher"
    }

    static var diagnosticsSummary: String {
        "Bundle ID: \(bundleIdentifier) - CloudKit container: \(containerIdentifier)"
    }

    enum Field {
        static let schemaVersion = "schemaVersion"
        static let scoreSchemaVersion = "scoreSchemaVersion"
        static let sourceResultID = "sourceResultID"
        static let deviceName = "deviceName"
        static let platform = "platform"
        static let osMajorVersion = "osMajorVersion"
        static let osMinorVersion = "osMinorVersion"
        static let appVersion = "appVersion"
        static let benchmarkIntensity = "benchmarkIntensity"
        static let graphicsBackend = "graphicsBackend"
        static let singleCoreScore = "singleCoreScore"
        static let multiCoreScore = "multiCoreScore"
        static let memoryScore = "memoryScore"
        static let memoryRawThroughputMBps = "memoryRawThroughputMBps"
        static let ssdScore = "ssdScore"
        static let ssdRawCombinedMBps = "ssdRawCombinedMBps"
        static let ssdRawReadMBps = "ssdRawReadMBps"
        static let ssdRawWriteMBps = "ssdRawWriteMBps"
        static let graphicsScore = "graphicsScore"
        static let overallScore = "overallScore"
        static let thermalState = "thermalState"
        static let wasConnectedToPower = "wasConnectedToPower"
        static let reliability = "reliability"
        static let validationMessageCount = "validationMessageCount"
        static let moderationState = "moderationState"
        static let isExcludedFromCommunityStats = "isExcludedFromCommunityStats"
        static let uploadedAt = "uploadedAt"
    }

    static let inspectableFields: [String] = [
        Field.schemaVersion,
        Field.scoreSchemaVersion,
        Field.sourceResultID,
        Field.deviceName,
        Field.platform,
        Field.osMajorVersion,
        Field.osMinorVersion,
        Field.appVersion,
        Field.benchmarkIntensity,
        Field.graphicsBackend,
        Field.singleCoreScore,
        Field.multiCoreScore,
        Field.memoryScore,
        Field.memoryRawThroughputMBps,
        Field.ssdScore,
        Field.ssdRawCombinedMBps,
        Field.ssdRawReadMBps,
        Field.ssdRawWriteMBps,
        Field.graphicsScore,
        Field.overallScore,
        Field.thermalState,
        Field.wasConnectedToPower,
        Field.reliability,
        Field.validationMessageCount,
        Field.moderationState,
        Field.isExcludedFromCommunityStats,
        Field.uploadedAt
    ]

    static func recordID(for resultID: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: "bencher-result-\(resultID.uuidString)")
    }

    static func makeRecord(from result: BenchmarkResult) -> CKRecord {
        let record = CKRecord(recordType: recordType, recordID: recordID(for: result.id))
        let version = ProcessInfo.processInfo.operatingSystemVersion

        record[Field.schemaVersion] = schemaVersion as CKRecordValue
        record[Field.scoreSchemaVersion] = scoreSchemaVersion as CKRecordValue
        record[Field.sourceResultID] = result.id.uuidString as CKRecordValue
        record[Field.deviceName] = result.deviceName as CKRecordValue
        record[Field.platform] = currentPlatform as CKRecordValue
        record[Field.osMajorVersion] = version.majorVersion as CKRecordValue
        record[Field.osMinorVersion] = version.minorVersion as CKRecordValue
        record[Field.appVersion] = BencherAppMetadata.versionString as CKRecordValue
        record[Field.benchmarkIntensity] = result.benchmarkIntensity as CKRecordValue
        record[Field.graphicsBackend] = result.graphicsBackend as CKRecordValue
        record[Field.singleCoreScore] = result.singleCoreScore as CKRecordValue
        record[Field.multiCoreScore] = result.cpuScore as CKRecordValue
        record[Field.memoryScore] = result.memoryScore as CKRecordValue
        record[Field.memoryRawThroughputMBps] = result.memoryRawThroughputMBps as CKRecordValue
        record[Field.ssdScore] = result.ssdScore as CKRecordValue
        record[Field.ssdRawCombinedMBps] = result.ssdRawCombinedMBps as CKRecordValue
        record[Field.ssdRawReadMBps] = result.ssdRawReadMBps as CKRecordValue
        record[Field.ssdRawWriteMBps] = result.ssdRawWriteMBps as CKRecordValue
        record[Field.graphicsScore] = result.graphicsScore as CKRecordValue
        record[Field.overallScore] = result.overallScore as CKRecordValue
        record[Field.thermalState] = result.thermalState as CKRecordValue
        if let wasConnectedToPower = result.wasConnectedToPower {
            record[Field.wasConnectedToPower] = (wasConnectedToPower ? 1 : 0) as CKRecordValue
        }
        record[Field.reliability] = result.reliability.rawValue as CKRecordValue
        record[Field.validationMessageCount] = result.validationMessages.count as CKRecordValue
        record[Field.moderationState] = CommunityModerationState.active.rawValue as CKRecordValue
        record[Field.isExcludedFromCommunityStats] = (result.isCommunityAverageEligible ? 0 : 1) as CKRecordValue
        record[Field.uploadedAt] = Date() as CKRecordValue
        return record
    }

    private static var currentPlatform: String {
        #if os(macOS)
        "macOS"
        #elseif os(iOS)
        "iOS"
        #elseif os(visionOS)
        "visionOS"
        #else
        "Apple"
        #endif
    }
}

extension BenchmarkResult {
    var isCommunityAverageEligible: Bool {
        reliability == .good
        && validationMessages.isEmpty
        && benchmarkIntensity == preferredReferenceBenchmarkIntensity
        && graphicsBackend == GraphicsBenchmarkBackend.metal.rawValue
        && thermalState < 2
    }
}

enum CommunityUploadedResultStore {
    private static let key = "communityResultsUploadedRecordNames"

    static func contains(recordName: String) -> Bool {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? []).contains(recordName)
    }

    static func insert(recordName: String) {
        var names = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        names.insert(recordName)
        UserDefaults.standard.set(Array(names).sorted(), forKey: key)
    }

    static func remove(recordName: String) {
        var names = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        names.remove(recordName)
        UserDefaults.standard.set(Array(names).sorted(), forKey: key)
    }
}

@MainActor
final class CommunityResultsModel: ObservableObject {
    @Published private(set) var results: [CommunityBenchmarkResult] = []
    @Published private(set) var isLoading = false
    @Published private(set) var message: String?

    private let service = CommunityResultsService()

    var groups: [CommunityResultGroup] {
        CommunityResultGroup.grouped(from: results)
    }

    func load() async {
        isLoading = true
        message = nil
        do {
            let raw = try await service.fetchRecentResults()
            results = Self.deduplicateBySourceResultID(raw)
            if results.isEmpty {
                message = "No community results have been uploaded yet."
            }
        } catch {
            message = "Couldn't load community results. \(error.localizedDescription)"
        }
        isLoading = false
    }

    // The same originating run can land on the server more than once when a user
    // had iCloud history sync on across devices and each device re-uploaded the
    // same UUID. Keep one record per `sourceResultID`, preferring the newest
    // upload, so duplicate copies of the same run never inflate the sample count.
    private static func deduplicateBySourceResultID(_ results: [CommunityBenchmarkResult]) -> [CommunityBenchmarkResult] {
        var seen: [String: CommunityBenchmarkResult] = [:]
        for result in results {
            if let existing = seen[result.sourceResultID] {
                if result.uploadedAt > existing.uploadedAt {
                    seen[result.sourceResultID] = result
                }
            } else {
                seen[result.sourceResultID] = result
            }
        }
        return Array(seen.values)
    }
}

enum CommunityResultsServiceError: LocalizedError {
    case iCloudAccountRequired
    case cloudKitContainerUnavailable(containerIdentifier: String, bundleIdentifier: String, underlyingMessage: String)

    var errorDescription: String? {
        switch self {
        case .iCloudAccountRequired:
            return "You need to be signed into iCloud to upload. You can still browse community results without it."
        case .cloudKitContainerUnavailable(_, _, let underlyingMessage):
            return "Bencher couldn't reach the community results store on iCloud. (\(underlyingMessage))"
        }
    }
}

struct CommunityResultsService {
    private let container = CKContainer.default()

    func fetchRecentResults(limit: Int = 400) async throws -> [CommunityBenchmarkResult] {
        do {
            let database = container.publicCloudDatabase
            let predicate = NSPredicate(format: "%K == %d", CommunityBenchmarkRecord.Field.schemaVersion, CommunityBenchmarkRecord.schemaVersion)
            let query = CKQuery(recordType: CommunityBenchmarkRecord.recordType, predicate: predicate)

            let response = try await database.records(
                matching: query,
                desiredKeys: CommunityBenchmarkRecord.inspectableFields,
                resultsLimit: limit
            )

            return response.matchResults.compactMap { _, result in
                guard case .success(let record) = result else { return nil }
                return CommunityBenchmarkResult(record: record)
            }
        } catch {
            throw mappedCloudKitError(error)
        }
    }

    func isUploaded(_ result: BenchmarkResult) async throws -> Bool {
        let recordID = CommunityBenchmarkRecord.recordID(for: result.id)
        if CommunityUploadedResultStore.contains(recordName: recordID.recordName) {
            return true
        }

        do {
            _ = try await container.publicCloudDatabase.record(for: recordID)
            CommunityUploadedResultStore.insert(recordName: recordID.recordName)
            return true
        } catch {
            if isRecordNotFound(error) {
                CommunityUploadedResultStore.remove(recordName: recordID.recordName)
                return false
            }
            throw mappedCloudKitError(error)
        }
    }

    func upload(_ result: BenchmarkResult) async throws {
        do {
            try await requireAvailableICloudAccount()

            if try await isUploaded(result) {
                return
            }

            let record = CommunityBenchmarkRecord.makeRecord(from: result)
            _ = try await container.publicCloudDatabase.save(record)
            CommunityUploadedResultStore.insert(recordName: record.recordID.recordName)
        } catch {
            throw mappedCloudKitError(error)
        }
    }

    static let maxUploadsPerDeviceGroup = 20

    func uploadAll(
        _ results: [BenchmarkResult],
        progress: (@Sendable (Int, Int) -> Void)? = nil
    ) async throws -> CommunityBulkUploadSummary {
        do {
            try await requireAvailableICloudAccount()
        } catch {
            throw mappedCloudKitError(error)
        }

        let totalCount = results.count
        var uploadedCount = 0
        var skippedAlreadyUploadedCount = 0
        var skippedDueToCapCount = 0
        var failedCount = 0
        var averageEligibleCount = 0
        var excludedFromAveragesCount = 0
        var wasCancelled = false

        // Per-device cap: limit total community uploads per (device, intensity, backend)
        // to `maxUploadsPerDeviceGroup`, so a single heavy-bencher cannot dominate the
        // public averages. Existing server-side uploads count toward the cap via the
        // local uploaded-record cache, so the cap is honoured across sessions.
        let grouped = Dictionary(grouping: results) { result -> String in
            "\(result.deviceName)|\(result.benchmarkIntensity)|\(result.graphicsBackend)"
        }

        var allowedNew: [BenchmarkResult] = []
        var preUploaded: [BenchmarkResult] = []

        for (_, members) in grouped {
            let sortedByRecent = members.sorted { $0.timestamp > $1.timestamp }
            var alreadyUploadedInGroup = 0
            var pendingInGroup: [BenchmarkResult] = []
            for member in sortedByRecent {
                let recordID = CommunityBenchmarkRecord.recordID(for: member.id)
                if CommunityUploadedResultStore.contains(recordName: recordID.recordName) {
                    alreadyUploadedInGroup += 1
                    preUploaded.append(member)
                } else {
                    pendingInGroup.append(member)
                }
            }
            let remainingCapacity = max(0, Self.maxUploadsPerDeviceGroup - alreadyUploadedInGroup)
            if pendingInGroup.count <= remainingCapacity {
                allowedNew.append(contentsOf: pendingInGroup)
            } else {
                allowedNew.append(contentsOf: pendingInGroup.prefix(remainingCapacity))
                skippedDueToCapCount += pendingInGroup.count - remainingCapacity
            }
        }

        skippedAlreadyUploadedCount = preUploaded.count

        let reportProgress: (Bool) -> Void = { force in
            let completed = uploadedCount + skippedAlreadyUploadedCount + skippedDueToCapCount + failedCount
            if force || completed % 10 == 0 || completed == totalCount {
                progress?(completed, totalCount)
            }
        }
        reportProgress(true)

        let pending = allowedNew.map { result -> (BenchmarkResult, CKRecord) in
            (result, CommunityBenchmarkRecord.makeRecord(from: result))
        }

        let database = container.publicCloudDatabase
        let chunkSize = 100
        var index = 0

        while index < pending.count {
            if Task.isCancelled {
                wasCancelled = true
                break
            }

            let end = min(index + chunkSize, pending.count)
            let chunk = Array(pending[index..<end])
            let outcomes = await performBulkSaveChunk(database: database, records: chunk.map(\.1))

            for (entry, outcome) in zip(chunk, outcomes) {
                let (result, record) = entry
                switch outcome {
                case .uploaded:
                    CommunityUploadedResultStore.insert(recordName: record.recordID.recordName)
                    uploadedCount += 1
                    if result.isCommunityAverageEligible {
                        averageEligibleCount += 1
                    } else {
                        excludedFromAveragesCount += 1
                    }
                case .alreadyOnServer:
                    CommunityUploadedResultStore.insert(recordName: record.recordID.recordName)
                    skippedAlreadyUploadedCount += 1
                case .failed:
                    failedCount += 1
                }
            }

            index = end
            reportProgress(true)
        }

        return CommunityBulkUploadSummary(
            uploadedCount: uploadedCount,
            skippedAlreadyUploadedCount: skippedAlreadyUploadedCount,
            skippedDueToCapCount: skippedDueToCapCount,
            failedCount: failedCount,
            averageEligibleCount: averageEligibleCount,
            excludedFromAveragesCount: excludedFromAveragesCount,
            totalCount: totalCount,
            wasCancelled: wasCancelled
        )
    }

    private enum BulkSaveOutcome {
        case uploaded
        case alreadyOnServer
        case failed
    }

    private func performBulkSaveChunk(database: CKDatabase, records: [CKRecord]) async -> [BulkSaveOutcome] {
        var outcomes = [BulkSaveOutcome](repeating: .failed, count: records.count)
        var attemptsRemaining = 2

        while attemptsRemaining > 0 {
            if Task.isCancelled { return outcomes }
            attemptsRemaining -= 1
            do {
                let response = try await database.modifyRecords(
                    saving: records,
                    deleting: [],
                    savePolicy: .ifServerRecordUnchanged,
                    atomically: false
                )

                for (offset, record) in records.enumerated() {
                    guard let perRecord = response.saveResults[record.recordID] else {
                        outcomes[offset] = .failed
                        continue
                    }
                    switch perRecord {
                    case .success:
                        outcomes[offset] = .uploaded
                    case .failure(let error):
                        if let ckError = error as? CKError, ckError.code == .serverRecordChanged {
                            outcomes[offset] = .alreadyOnServer
                        } else {
                            outcomes[offset] = .failed
                        }
                    }
                }
                return outcomes
            } catch {
                if attemptsRemaining > 0,
                   let ckError = error as? CKError,
                   let retryAfter = ckError.retryAfterSeconds,
                   retryAfter > 0, retryAfter < 30 {
                    try? await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                    continue
                }
                return outcomes
            }
        }

        return outcomes
    }

    func deleteUpload(for result: BenchmarkResult) async throws {
        let recordID = CommunityBenchmarkRecord.recordID(for: result.id)
        do {
            _ = try await container.publicCloudDatabase.deleteRecord(withID: recordID)
            CommunityUploadedResultStore.remove(recordName: recordID.recordName)
        } catch {
            if isRecordNotFound(error) {
                CommunityUploadedResultStore.remove(recordName: recordID.recordName)
                return
            }
            throw mappedCloudKitError(error)
        }
    }

    private func requireAvailableICloudAccount() async throws {
        let status = try await container.accountStatus()
        guard status == .available else {
            throw CommunityResultsServiceError.iCloudAccountRequired
        }
    }

    private func mappedCloudKitError(_ error: Error) -> Error {
        if let serviceError = error as? CommunityResultsServiceError {
            return serviceError
        }

        let message = detailedCloudKitMessage(for: error)
        if message.localizedCaseInsensitiveContains("Invalid bundle ID")
            || message.localizedCaseInsensitiveContains("not entitled")
            || message.localizedCaseInsensitiveContains("Missing entitlement") {
            return CommunityResultsServiceError.cloudKitContainerUnavailable(
                containerIdentifier: CommunityBenchmarkRecord.containerIdentifier,
                bundleIdentifier: CommunityBenchmarkRecord.bundleIdentifier,
                underlyingMessage: message
            )
        }

        return NSError(
            domain: "Bencher.CommunityResults",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    private func detailedCloudKitMessage(for error: Error) -> String {
        guard let ckError = error as? CKError else {
            return error.localizedDescription
        }

        var parts = ["\(ckError.localizedDescription) (CKError.\(ckError.code))"]
        if let retryAfter = ckError.retryAfterSeconds, retryAfter > 0 {
            parts.append("Retry after \(String(format: "%.0f", retryAfter)) seconds")
        }
        return parts.joined(separator: " ")
    }

    private func isRecordNotFound(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        return ckError.code == .unknownItem
    }
}

private enum CommunitySheetItem: Identifiable {
    case group(CommunityResultGroup)
    case result(CommunityBenchmarkResult)

    var id: String {
        switch self {
        case .group(let group): return "group-\(group.id)"
        case .result(let result): return "result-\(result.id)"
        }
    }
}

struct CommunityResultsView: View {
    @StateObject private var model = CommunityResultsModel()
    @AppStorage("communityResultsAllowExperimental") private var allowExperimentalResults: Bool = false
    @State private var leaderboardMode: CommunityLeaderboardMode = .averages
    @State private var selectedDevice: String = "All Devices"
    @State private var selectedMode: String = "All Modes"
    @State private var selectedGraphicsBackend: String = "All Graphics Paths"
    @State private var activeSheet: CommunitySheetItem? = nil

    private var filteredGroups: [CommunityResultGroup] {
        model.groups.filter { group in
            let matchesDevice = selectedDevice == "All Devices" || group.deviceName == selectedDevice
            let matchesMode = selectedMode == "All Modes" || group.benchmarkIntensity == selectedMode
            let matchesGraphics = selectedGraphicsBackend == "All Graphics Paths" || group.graphicsBackend == selectedGraphicsBackend
            // Hide groups whose every uploaded result is excluded from stats — they
            // would render as score-less cards in the Averages view. Such results
            // are still browsable individually under the Results tab.
            guard let statistics = group.overallStatistics else { return false }
            return matchesDevice && matchesMode && matchesGraphics && (allowExperimentalResults || statistics.isStable)
        }
    }

    private var filteredResults: [CommunityBenchmarkResult] {
        model.results
            .filter { result in
                let matchesDevice = selectedDevice == "All Devices" || result.deviceName == selectedDevice
                let matchesMode = selectedMode == "All Modes" || result.benchmarkIntensity == selectedMode
                let matchesGraphics = selectedGraphicsBackend == "All Graphics Paths" || result.graphicsBackend == selectedGraphicsBackend
                return matchesDevice && matchesMode && matchesGraphics && result.moderationState == CommunityModerationState.active.rawValue
            }
            .sorted { lhs, rhs in
                if lhs.overallScore == rhs.overallScore {
                    return lhs.uploadedAt > rhs.uploadedAt
                }
                return lhs.overallScore > rhs.overallScore
            }
    }

    private var deviceOptions: [String] {
        ["All Devices"] + Array(Set(model.results.map(\.deviceName))).sorted()
    }

    // In Results mode every uploaded result is shown regardless of the stored
    // preference, so we surface that fact by reporting the toggle as "on" without
    // touching the saved Averages-mode setting underneath.
    private var experimentalToggleBinding: Binding<Bool> {
        Binding(
            get: { leaderboardMode == .results ? true : allowExperimentalResults },
            set: { newValue in
                guard leaderboardMode == .averages else { return }
                allowExperimentalResults = newValue
            }
        )
    }

    private var modeOptions: [String] {
        ["All Modes"] + Array(Set(model.results.map(\.benchmarkIntensity))).sorted()
    }

    private var graphicsOptions: [String] {
        ["All Graphics Paths"] + Array(Set(model.results.map(\.graphicsBackend))).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                filters

                if model.isLoading {
                    ProgressView("Loading community results...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .glassCard(cornerRadius: 18)
                } else if let message = model.message, model.results.isEmpty {
                    emptyState(message)
                } else if leaderboardMode == .averages {
                    averagedResultsContent
                } else {
                    rawResultsContent
                }
            }
            .padding()
        }
        .navigationTitle("Community Results")
        .bencherInlineTitleDisplayMode()
        .task {
            await model.load()
        }
        .refreshable {
            await model.load()
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .group(let group):
                CommunityGroupDetailSheet(group: group) { result in
                    activeSheet = .result(result)
                }
            case .result(let result):
                CommunityResultDetailSheet(result: result)
            }
        }
    }

    @ViewBuilder
    private var averagedResultsContent: some View {
        if filteredGroups.isEmpty {
            emptyState(allowExperimentalResults ? "Nothing matches these filters yet." : "No solid averages match these filters yet. Turn on experimental groups to include groups with fewer samples.")
        } else {
            VStack(spacing: 12) {
                ForEach(filteredGroups) { group in
                    Button {
                        activeSheet = .group(group)
                    } label: {
                        CommunityResultGroupCard(group: group)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var rawResultsContent: some View {
        if filteredResults.isEmpty {
            emptyState("No individual results match these filters yet.")
        } else {
            VStack(spacing: 12) {
                ForEach(Array(filteredResults.prefix(50).enumerated()), id: \.element.id) { index, result in
                    Button {
                        activeSheet = .result(result)
                    } label: {
                        CommunityRawResultCard(
                            rank: index + 1,
                            result: result,
                            isYours: CommunityUploadedResultStore.contains(recordName: result.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue.opacity(0.16))
                        .frame(width: 48, height: 48)
                    Image(systemName: "person.3.sequence.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Community Results")
                        .font(.title2.bold())
                    Text("Anonymous results grouped by device, mode and graphics path.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Picker("Community View", selection: $leaderboardMode) {
                ForEach(CommunityLeaderboardMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Show experimental groups", isOn: experimentalToggleBinding)
                .font(.subheadline.weight(.semibold))

            Text("Averages drop extreme highs and lows so they reflect typical performance. Individual runs live in their own tab.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Device", selection: $selectedDevice) {
                ForEach(deviceOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }

            Picker("Mode", selection: $selectedMode) {
                ForEach(modeOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }

            Picker("Graphics", selection: $selectedGraphicsBackend) {
                ForEach(graphicsOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        }
        .pickerStyle(.menu)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
    }

    private func emptyState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 38))
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassCard(cornerRadius: 18)
    }
}

private struct CommunityResultGroupCard: View {
    let group: CommunityResultGroup

    private var statistics: CommunityResultStatistics? {
        group.overallStatistics
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.deviceName)
                        .font(.headline)
                        .lineLimit(2)
                    Text("\(group.benchmarkIntensity) - \(group.graphicsBackend)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 8)

                if let statistics {
                    Text(statistics.isStable ? "Stable" : "Experimental")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(statistics.isStable ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background((statistics.isStable ? Color.green : Color.orange).opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if let statistics {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(String(format: "%.0f", statistics.median))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Median Overall")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 126), spacing: 10)], spacing: 10) {
                    statTile(title: "Single-Core", stats: group.singleCoreStatistics)
                    statTile(title: "Multi-Core", stats: group.multiCoreStatistics)
                    statTile(title: "GPU", stats: group.graphicsStatistics)
                    statTile(title: "Samples", value: "\(statistics.filteredSampleCount)/\(statistics.sampleCount)")
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
    }

    private func statTile(title: String, value: Double) -> some View {
        statTile(title: title, value: String(format: "%.0f", value))
    }

    private func statTile(title: String, stats: CommunityResultStatistics?) -> some View {
        statTile(title: title, value: stats.map { String(format: "%.0f", $0.median) } ?? "—")
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct CommunityRawResultCard: View {
    let rank: Int
    let result: CommunityBenchmarkResult
    var isYours: Bool = false

    private var rankAccentColor: Color {
        if isYours { return .green }
        return rank <= 3 ? .orange : .blue
    }

    private var scoreAccentColor: Color {
        isYours ? .green : .blue
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 4) {
                Image(systemName: isYours ? "person.fill" : (rank <= 3 ? "trophy.fill" : "list.number"))
                    .font(.caption.weight(.bold))
                Text("#\(rank)")
                    .font(.caption.weight(.bold))
            }
            .foregroundColor(rankAccentColor)
            .frame(width: 46, height: 46)
            .background(rankAccentColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(format: "%.0f", result.overallScore))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(scoreAccentColor)
                    Text("Overall")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Spacer(minLength: 0)
                    if isYours {
                        Text("You")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(result.deviceName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text("\(result.benchmarkIntensity) - \(result.graphicsBackend) - \(result.uploadedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    metricPill(title: "SC", value: result.singleCoreScore)
                    metricPill(title: "MC", value: result.multiCoreScore)
                    metricPill(title: "GPU", value: result.graphicsScore)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.green.opacity(isYours ? 0.45 : 0), lineWidth: isYours ? 1.5 : 0)
        )
    }

    private func metricPill(title: String, value: Double) -> some View {
        Text("\(title) \(String(format: "%.0f", value))")
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .clipShape(Capsule())
    }
}

private struct CommunityResultDetailContent: View {
    let result: CommunityBenchmarkResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerCard
                scoreGrid
                environmentCard
                detailsCard
            }
            .padding()
        }
        .navigationTitle("Result")
        .bencherInlineTitleDisplayMode()
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.deviceName)
                .font(.title2.bold())
            Text("\(result.benchmarkIntensity) - \(result.graphicsBackend)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.0f", result.overallScore))
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.blue)
                Text("Overall")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(cornerRadius: 18)
    }

    private var scoreGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
            scoreTile("Single-Core", value: result.singleCoreScore)
            scoreTile("Multi-Core", value: result.multiCoreScore)
            scoreTile("Memory", value: result.memoryScore)
            scoreTile("SSD", value: result.ssdScore)
            scoreTile("GPU", value: result.graphicsScore)
        }
    }

    private var environmentCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Environment")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
            Text("Thermal: \(thermalLabel(result.thermalState))")
                .font(.subheadline)
            if let onPower = result.wasConnectedToPower {
                Text("Power: \(onPower ? "Plugged in" : "On battery")")
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(cornerRadius: 18)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Details")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
            Text("\(result.platform) \(result.osMajorVersion).\(result.osMinorVersion) - Bencher \(result.appVersion)")
                .font(.subheadline)
            Text("Uploaded \(result.uploadedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Reliability: \(result.reliability)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(cornerRadius: 18)
    }

    private func scoreTile(_ title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", value))
                .font(.title3.bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func thermalLabel(_ state: Int) -> String {
        switch state {
        case 0: return "Nominal"
        case 1: return "Fair"
        case 2: return "Serious"
        case 3: return "Critical"
        default: return "Unknown"
        }
    }
}

private struct CommunityResultDetailSheet: View {
    let result: CommunityBenchmarkResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CommunityResultDetailContent(result: result)
                .toolbar {
                    ToolbarItem(placement: .bencherTopBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

private struct CommunityGroupDetailSheet: View {
    let group: CommunityResultGroup
    let onSelectResult: (CommunityBenchmarkResult) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    summary
                    ForEach(Array(group.results.enumerated()), id: \.element.id) { index, result in
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                onSelectResult(result)
                            }
                        } label: {
                            CommunityRawResultCard(
                                rank: index + 1,
                                result: result,
                                isYours: CommunityUploadedResultStore.contains(recordName: result.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle(group.deviceName)
            .bencherInlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .bencherTopBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(group.benchmarkIntensity) - \(group.graphicsBackend)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            Text("\(group.results.count) result\(group.results.count == 1 ? "" : "s") in this group")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(cornerRadius: 18)
    }
}

struct CommunityUploadCard: View {
    let result: BenchmarkResult
    @State private var uploadState: CommunityUploadState = .checkingStatus
    @State private var isShowingUploadConfirmation = false
    @State private var isShowingDeleteConfirmation = false

    private let service = CommunityResultsService()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "person.3.sequence.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Community Results")
                        .font(.headline)
                    Text("Share this run anonymously to help build the public averages.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Shares: device, OS, app version, mode, graphics path, scores, thermal and power state. Doesn't share: notes, tags, favourites or session info.")
                .font(.caption)
                .foregroundColor(.secondary)

            switch uploadState {
            case .idle:
                Button {
                    isShowingUploadConfirmation = true
                } label: {
                    Label("Upload Result", systemImage: "icloud.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            case .checkingStatus:
                ProgressView("Checking...")
            case .checkingAccount, .uploading:
                ProgressView(uploadState == .checkingAccount ? "Checking iCloud..." : "Uploading...")
            case .uploaded:
                HStack(spacing: 10) {
                    Label("Shared with the community", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green)
                    Spacer(minLength: 0)
                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            case .deleting:
                ProgressView("Removing upload...")
            case .failed(let message):
                VStack(alignment: .leading, spacing: 8) {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Button("Try Again") {
                            isShowingUploadConfirmation = true
                        }
                        .buttonStyle(.bordered)

                        Button("Check Status") {
                            Task {
                                await refreshUploadStatus()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
        .task(id: result.id) {
            await refreshUploadStatus()
        }
        .confirmationDialog("Upload Community Result", isPresented: $isShowingUploadConfirmation, titleVisibility: .visible) {
            Button("Upload Result") {
                Task {
                    await upload()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Uploads only the benchmark numbers — no notes, tags or favourites. You need iCloud to upload, but not to browse.")
        }
        .confirmationDialog("Remove Community Upload", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Remove Upload", role: .destructive) {
                Task {
                    await deleteUpload()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Removes this run from the public dataset. The local copy stays in your History.")
        }
    }

    @MainActor
    private func refreshUploadStatus() async {
        uploadState = .checkingStatus
        do {
            uploadState = try await service.isUploaded(result) ? .uploaded : .idle
        } catch {
            uploadState = .failed(error.localizedDescription)
        }
    }

    @MainActor
    private func upload() async {
        uploadState = .checkingAccount
        do {
            uploadState = .uploading
            try await service.upload(result)
            uploadState = .uploaded
            Haptics.success()
        } catch {
            uploadState = .failed(error.localizedDescription)
            Haptics.warning()
        }
    }

    @MainActor
    private func deleteUpload() async {
        uploadState = .deleting
        do {
            try await service.deleteUpload(for: result)
            uploadState = .idle
            Haptics.success()
        } catch {
            uploadState = .failed(error.localizedDescription)
            Haptics.warning()
        }
    }
}
