//
//  ContentView.swift
//  Bencher
//
//  Created by Adam Ibrahim on 19/11/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import Charts
import CryptoKit
#if canImport(Metal)
import Metal
#endif
#if os(macOS)
import OpenCL
#endif

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Main ContentView
struct ContentView: View {
    @State private var scores: [BenchmarkResult] = BenchmarkStorage.load()
    @AppStorage("appAppearanceMode") private var appAppearanceMode: String = "Dark"
    @AppStorage("icloudHistorySyncEnabled") private var iCloudHistorySyncEnabled: Bool = false
    @State private var selectedTab: String = "dashboard"
    @State private var pendingHistoryAction: DashboardHistoryAction? = nil
    @State private var pendingHistorySelection: BenchmarkResult.ID? = nil
    @State private var hasPreparedStorage: Bool = false

    private var usesSettingsHostedUpdatesOnIOS: Bool {
        #if canImport(UIKit)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(sidebarItems) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .tag(item.id)
                }
            }
            .navigationTitle("Bencher")
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
        } detail: {
            selectedRootView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            guard !hasPreparedStorage else { return }
            BenchmarkStorage.prepareForLaunch()
            scores = BenchmarkStorage.load()
            hasPreparedStorage = true
        }
        .onChange(of: iCloudHistorySyncEnabled) { _, isEnabled in
            scores = BenchmarkStorage.setICloudSyncEnabled(isEnabled, currentScores: scores)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)) { _ in
            guard iCloudHistorySyncEnabled else { return }
            scores = BenchmarkStorage.load()
        }
        #else
        TabView(selection: $selectedTab) {
            DashboardView(scores: scores, selectedTab: $selectedTab, pendingHistoryAction: $pendingHistoryAction)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
                .tag("dashboard")

            BenchmarkView(scores: $scores)
                .tabItem {
                    Label("Benchmark", systemImage: "speedometer")
                }
                .tag("benchmark")

            HistoryView(scores: $scores, pendingAction: $pendingHistoryAction, pendingSelectedResultID: $pendingHistorySelection)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                .tag("history")

            TrendsView(scores: scores, selectedTab: $selectedTab, pendingHistorySelection: $pendingHistorySelection)
                .tabItem {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag("trends")
            
            ReferenceDevicesView(scores: scores)
                .tabItem {
                    Label("Reference", systemImage: "iphone.gen3")
                }
                .tag("reference")

            SettingsView(latestResult: scores.sorted(by: { $0.timestamp > $1.timestamp }).first)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag("settings")

            if !usesSettingsHostedUpdatesOnIOS {
                UpdatesView()
                    .tabItem {
                        Label("Updates", systemImage: "clock.badge.checkmark")
                    }
                    .tag("updates")
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            guard !hasPreparedStorage else { return }
            BenchmarkStorage.prepareForLaunch()
            scores = BenchmarkStorage.load()
            hasPreparedStorage = true
        }
        .onChange(of: iCloudHistorySyncEnabled) { _, isEnabled in
            scores = BenchmarkStorage.setICloudSyncEnabled(isEnabled, currentScores: scores)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)) { _ in
            guard iCloudHistorySyncEnabled else { return }
            scores = BenchmarkStorage.load()
        }
        #endif
    }

    private var preferredColorScheme: ColorScheme? {
        switch appAppearanceMode {
        case "Light":
            return .light
        case "Dark":
            return .dark
        default:
            return nil
        }
    }

    private var sidebarItems: [SidebarItem] {
        [
            SidebarItem(id: "dashboard", title: "Dashboard", systemImage: "square.grid.2x2"),
            SidebarItem(id: "benchmark", title: "Benchmark", systemImage: "speedometer"),
            SidebarItem(id: "history", title: "History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"),
            SidebarItem(id: "trends", title: "Trends", systemImage: "chart.line.uptrend.xyaxis"),
            SidebarItem(id: "reference", title: "Reference", systemImage: "iphone.gen3"),
            SidebarItem(id: "settings", title: "Settings", systemImage: "gearshape"),
            SidebarItem(id: "updates", title: "Updates", systemImage: "clock.badge.checkmark")
        ]
    }

    @ViewBuilder
    private var selectedRootView: some View {
        switch selectedTab {
        case "dashboard":
            DashboardView(scores: scores, selectedTab: $selectedTab, pendingHistoryAction: $pendingHistoryAction)
        case "benchmark":
            BenchmarkView(scores: $scores)
        case "history":
            HistoryView(scores: $scores, pendingAction: $pendingHistoryAction, pendingSelectedResultID: $pendingHistorySelection)
        case "trends":
            TrendsView(scores: scores, selectedTab: $selectedTab, pendingHistorySelection: $pendingHistorySelection)
        case "reference":
            ReferenceDevicesView(scores: scores)
        case "settings":
            SettingsView(latestResult: scores.sorted(by: { $0.timestamp > $1.timestamp }).first)
        case "updates":
            UpdatesView()
        default:
            DashboardView(scores: scores, selectedTab: $selectedTab, pendingHistoryAction: $pendingHistoryAction)
        }
    }
}

private struct SidebarItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
}

enum BencherPlatformColors {
    static var systemBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.white
        #endif
    }

    static var secondaryBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.gray.opacity(0.1)
        #endif
    }
}

private enum BencherSupport {
    private struct EncryptedFeedbackSecrets: Decodable {
        let feedbackEmailBox: String
    }

    private static let keyResourceName = "FeedbackSecrets"
    private static let keyResourceExtension = "key"
    private static let encryptedResourceName = "FeedbackSecrets"
    private static let encryptedResourceExtension = "enc.json"

    static func feedbackEmailAddress() -> String? {
        guard Bundle.main.url(forResource: keyResourceName, withExtension: keyResourceExtension) != nil,
              let encryptedURL = Bundle.main.url(forResource: encryptedResourceName, withExtension: encryptedResourceExtension),
              let encryptedData = try? Data(contentsOf: encryptedURL),
              let secrets = try? JSONDecoder().decode(EncryptedFeedbackSecrets.self, from: encryptedData),
              let combinedBox = Data(base64Encoded: secrets.feedbackEmailBox),
              let sealedBox = try? AES.GCM.SealedBox(combined: combinedBox) else {
            return nil
        }

        guard let key = BencherCrypto.feedbackKey() else { return nil }
        guard let decryptedData = try? AES.GCM.open(sealedBox, using: key),
              let emailAddress = String(data: decryptedData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !emailAddress.isEmpty else {
            return nil
        }

        return emailAddress
    }
}

private enum BencherCrypto {
    private static let masterKeyResourceName = "FeedbackSecrets"
    private static let masterKeyResourceExtension = "key"

    static func encryptStoragePayload(_ data: Data) -> Data? {
        guard let key = derivedKey(context: "benchmark-storage") else { return nil }
        guard let sealed = try? AES.GCM.seal(data, using: key).combined else { return nil }
        return sealed
    }

    static func decryptStoragePayload(_ data: Data) -> Data? {
        guard let key = derivedKey(context: "benchmark-storage"),
              let box = try? AES.GCM.SealedBox(combined: data),
              let opened = try? AES.GCM.open(box, using: key) else {
            return nil
        }
        return opened
    }

    static func feedbackKey() -> SymmetricKey? {
        guard let keyData = masterKeyData() else { return nil }
        return SymmetricKey(data: keyData)
    }

    private static func derivedKey(context: String) -> SymmetricKey? {
        guard let masterKey = feedbackKey() else { return nil }
        let salt = Data("Bencher.StandardEncryption.v1".utf8)
        let info = Data(context.utf8)
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: masterKey,
            salt: salt,
            info: info,
            outputByteCount: 32
        )
    }

    private static func masterKeyData() -> Data? {
        guard let keyURL = Bundle.main.url(forResource: masterKeyResourceName, withExtension: masterKeyResourceExtension),
              let keyFileData = try? Data(contentsOf: keyURL),
              let keyBase64 = String(data: keyFileData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              let keyData = Data(base64Encoded: keyBase64) else {
            return nil
        }

        return keyData
    }
}

extension ToolbarItemPlacement {
    static var bencherTopBarLeading: ToolbarItemPlacement {
        #if os(macOS)
        .cancellationAction
        #else
        .topBarLeading
        #endif
    }

    static var bencherTopBarTrailing: ToolbarItemPlacement {
        #if os(macOS)
        .primaryAction
        #else
        .topBarTrailing
        #endif
    }
}

extension View {
    @ViewBuilder
    func bencherInlineTitleDisplayMode() -> some View {
        #if os(macOS)
        self
        #else
        self.navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    func bencherItemCover<Item: Identifiable, CoverContent: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> CoverContent
    ) -> some View {
        #if os(macOS)
        self.sheet(item: item, content: content)
        #else
        self.fullScreenCover(item: item, content: content)
        #endif
    }
}

enum DashboardHistoryAction {
    case compare
    case export
}

// MARK: - Benchmark View
struct BenchmarkView: View {
    @Binding var scores: [BenchmarkResult]
    @AppStorage("benchmarkIntensity") private var benchmarkIntensity: String = "Balanced"
    @AppStorage("benchmarkRepeatCount") private var benchmarkRepeatCount: Int = 1
    @AppStorage("graphicsBenchmarkBackend") private var graphicsBenchmarkBackend: String = GraphicsBenchmarkBackend.metal.rawValue
    @Environment(\.colorScheme) private var colorScheme

    @State private var singleCoreScore: Double? = nil
    @State private var cpuScore: Double? = nil
    @State private var memoryScore: Double? = nil
    @State private var memoryRawThroughputMBps: Double? = nil
    @State private var ssdScore: Double? = nil
    @State private var ssdRawCombinedMBps: Double? = nil
    @State private var ssdRawReadMBps: Double? = nil
    @State private var ssdRawWriteMBps: Double? = nil
    @State private var graphicsScore: Double? = nil
    @State private var overallScore: Double? = nil

    @State private var isRunning: Bool = false
    @State private var benchmarkComplete: Bool = false
    @State private var benchmarkFailedMessage: String? = nil
    @State private var benchmarkValidationSummary: BenchmarkValidationSummary? = nil

    @State private var progressMessage: String = "Ready to benchmark!"
    @State private var overallProgress: Double = 0.0
    @State private var taskProgress: Double = 0.0
    @State private var benchmarkTask: DispatchWorkItem?

    var body: some View {
        ZStack {
            BencherPlatformColors.systemBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    benchmarkHero

                    benchmarkControlStrip

                    // Thermal warning UI
                    let thermal = ProcessInfo.processInfo.thermalState
                    if thermal == .critical {
                        benchmarkNotice("Device is at critical temps. Results will be reduced.", tint: .red, systemImage: "exclamationmark.octagon.fill")
                    }
                    else if thermal == .serious {
                        benchmarkNotice("Device is hot. Results may be reduced.", tint: .orange, systemImage: "thermometer.medium")
                    }
                    else if thermal != .nominal {
                        benchmarkNotice("Device is warm. Results may be reduced.", tint: .yellow, systemImage: "thermometer.low")
                    }

                    if let benchmarkFailedMessage = benchmarkFailedMessage {
                        Text(benchmarkFailedMessage)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.75))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal)
                    }

                    if let benchmarkValidationSummary, benchmarkValidationSummary.reliability == .caution {
                        benchmarkNotice(
                            benchmarkValidationSummary.primaryMessage ?? "This benchmark completed, but the result is worth treating with a little caution.",
                            tint: .orange,
                            systemImage: "exclamationmark.triangle.fill"
                        )
                    }

                    benchmarkProgressSection

                    if hasAnyVisibleScores {
                        benchmarkResultsHeader
                    }

                    if let singleCoreScore = singleCoreScore {
                        ScoreCard(
                            title: "Single-Core Score",
                            score: singleCoreScore,
                            color: metricColor(title: "Single-Core Score", score: singleCoreScore)
                        )
                    }

                    if let cpuScore = cpuScore {
                        ScoreCard(
                            title: "Multi-Core Score",
                            score: cpuScore,
                            color: metricColor(title: "Multi-Core Score", score: cpuScore)
                        )
                    }

                    if let memoryScore = memoryScore {
                        ScoreCard(
                            title: "Memory Score",
                            score: memoryScore,
                            color: metricColor(title: "Memory Score", score: memoryScore),
                            footerText: memoryRawThroughputMBps.map {
                                "Raw throughput: \(String(format: "%.0f", $0)) MB/s"
                            }
                        )
                    }

                    if let ssdScore = ssdScore {
                        ScoreCard(
                            title: "SSD Speed Score",
                            score: ssdScore,
                            color: metricColor(title: "SSD Speed Score", score: ssdScore),
                            footerText: {
                                if let read = ssdRawReadMBps, let write = ssdRawWriteMBps {
                                    return "Raw read/write: \(String(format: "%.0f", read))/\(String(format: "%.0f", write)) MB/s"
                                }
                                if let combined = ssdRawCombinedMBps {
                                    return "Raw combined speed: \(String(format: "%.0f", combined)) MB/s"
                                }
                                return nil
                            }()
                        )
                    }

                    if let graphicsScore = graphicsScore {
                        ScoreCard(
                            title: "Graphics Score",
                            score: graphicsScore,
                            color: metricColor(title: "Graphics Score", score: graphicsScore)
                        )
                    }

                    if let overallScore = overallScore {
                        ScoreCard(
                            title: "Overall Score",
                            score: overallScore,
                            color: metricColor(title: "Overall Score", score: overallScore),
                            isBold: true
                        )
                    }

                    if benchmarkComplete, let overallScore = overallScore {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Latest Run Summary")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Overall score: \(String(format: "%.0f", overallScore))")
                                .font(.title3.weight(.bold))
                                .foregroundColor(.primary)

                            Text("Benchmark type: \(benchmarkIntensity) • Stability runs: \(benchmarkRepeatCount)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(summaryText(overallScore: overallScore))
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(benchmarkCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    HStack(spacing: 12) {
                        Button(action: runBenchmark) {
                            Text(isRunning ? "Running..." : (benchmarkComplete ? "Run Again" : "Run Benchmark"))
                                .font(.title2)
                                .padding()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .background(isRunning ? Color.gray : Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(isRunning)

                        if isRunning {
                            Button(action: cancelBenchmark) {
                                Text("Cancel")
                                    .font(.title2)
                                    .padding()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                        } else if benchmarkComplete {
                            Button(action: acknowledgeBenchmarkCompletion) {
                                Text("OK")
                                    .font(.title2)
                                    .padding()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.top, 12)
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .safeAreaPadding(.top, 20)
            .scrollIndicators(.visible)
        }
    }

    private var benchmarkCardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }

    private var hasAnyVisibleScores: Bool {
        singleCoreScore != nil
        || cpuScore != nil
        || memoryScore != nil
        || ssdScore != nil
        || graphicsScore != nil
        || overallScore != nil
    }

    private var benchmarkHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to Bencher")
                        .font(.largeTitle.bold())
                    Text("See how your CPU, memory, storage and graphics perform with one quick run.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Image(systemName: "speedometer")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.blue)
                }
            }

            HStack(spacing: 10) {
                benchmarkIntensityMenuChip
                benchmarkStabilityMenuChip
                benchmarkInfoChip(title: benchmarkComplete ? "Ready" : (isRunning ? "In Progress" : "Idle"), systemImage: isRunning ? "waveform.path.ecg" : "checkmark.circle")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BencherTheme.cardGradient)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var benchmarkControlStrip: some View {
        HStack(spacing: 12) {
            benchmarkMiniCard(title: "Intensity", value: benchmarkIntensity, tint: .blue)
            benchmarkMiniCard(title: "Stability", value: "\(benchmarkRepeatCount) run\(benchmarkRepeatCount == 1 ? "" : "s")", tint: .green)
        }
    }

    private var benchmarkProgressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Benchmark Progress")
                        .font(.headline)
                    Text(isRunning ? "Progress bars currently updating." : "Progress bars will update here once a run starts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Overall Progress")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(Int(overallProgress * 100))%")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                ProgressBar(progress: $overallProgress, color: .green)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(progressMessage)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(Int(taskProgress * 100))%")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                ProgressBar(progress: $taskProgress, color: .blue)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(benchmarkCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var benchmarkResultsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Live Results")
                    .font(.headline)
                Text("Sections will be added here as the benchmark progresses.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func benchmarkMiniCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(benchmarkCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func benchmarkInfoChip(title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption)
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.06))
        .clipShape(Capsule())
    }

    private var benchmarkIntensityMenuChip: some View {
        Menu {
            ForEach(["Light", "Balanced", "Extreme"], id: \.self) { intensity in
                Button {
                    benchmarkIntensity = intensity
                } label: {
                    benchmarkMenuLabel(title: intensity, isSelected: benchmarkIntensity == intensity)
                }
            }
        } label: {
            benchmarkInfoChip(title: benchmarkIntensity, systemImage: "dial.medium")
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
    }

    private var benchmarkStabilityMenuChip: some View {
        Menu {
            ForEach([1, 3, 5], id: \.self) { runCount in
                Button {
                    benchmarkRepeatCount = runCount
                } label: {
                    benchmarkMenuLabel(
                        title: "\(runCount)x stability",
                        isSelected: benchmarkRepeatCount == runCount
                    )
                }
            }
        } label: {
            benchmarkInfoChip(title: "\(benchmarkRepeatCount)x stability", systemImage: "repeat")
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
    }

    @ViewBuilder
    private func benchmarkMenuLabel(title: String, isSelected: Bool) -> some View {
        Label {
            Text(title)
        } icon: {
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }

    private func benchmarkNotice(_ text: String, tint: Color, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(tint)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tint.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func runBenchmark() {
        isRunning = true
        benchmarkComplete = false
        benchmarkFailedMessage = nil
        benchmarkValidationSummary = nil
        progressMessage = "Starting benchmark..."
        overallProgress = 0.0
        taskProgress = 0.0

        var workItem: DispatchWorkItem!
        workItem = DispatchWorkItem {
            let benchmark = Benchmark(intensity: benchmarkIntensity, graphicsBackend: graphicsBenchmarkBackend)
            
            // Single-Core Benchmark
            DispatchQueue.main.async {
                progressMessage = "Running Single-Core benchmark..."
                taskProgress = 0.0
            }
            for step in 1...10 {
                if workItem.isCancelled { return }
                DispatchQueue.main.async {
                    taskProgress = Double(step) / 10.0
                }
                usleep(120_000)
            }
            guard !workItem.isCancelled else { return }
            let singleCoreResult = averageDoubleMeasurement(repeatCount: benchmarkRepeatCount) {
                benchmark.measureSingleCoreBenchmark()
            }
            DispatchQueue.main.async {
                singleCoreScore = singleCoreResult.rounded()
                taskProgress = 1.0
                overallProgress = 0.20
            }

            // Multi-Core Benchmark
            DispatchQueue.main.async {
                progressMessage = "Running Multi-Core benchmark..."
                taskProgress = 0.0
            }
            for step in 1...10 {
                if workItem.isCancelled { return }
                DispatchQueue.main.async {
                    taskProgress = Double(step) / 10.0
                }
                usleep(120_000)
            }
            guard !workItem.isCancelled else { return }
            let cpuResult = averageDoubleMeasurement(repeatCount: benchmarkRepeatCount) {
                benchmark.measureCPUBenchmark()
            }
            DispatchQueue.main.async {
                cpuScore = cpuResult.rounded()
                taskProgress = 1.0
                overallProgress = 0.40
            }

            // Memory Benchmark
            DispatchQueue.main.async {
                progressMessage = "Running Memory benchmark..."
                taskProgress = 0.0
            }
            for step in 1...10 {
                if workItem.isCancelled { return }
                DispatchQueue.main.async {
                    taskProgress = Double(step) / 10.0
                }
                usleep(90_000)
            }
            guard !workItem.isCancelled else { return }
            let memoryResult = averageMemoryMeasurement(repeatCount: benchmarkRepeatCount) {
                benchmark.measureMemoryBenchmark()
            }
            DispatchQueue.main.async {
                memoryScore = calibratedScore(title: "Memory Score", rawScore: memoryResult.score)
                memoryRawThroughputMBps = memoryResult.throughputMBps.rounded()
                taskProgress = 1.0
                overallProgress = 0.60
            }

            // SSD Benchmark
            DispatchQueue.main.async {
                progressMessage = "Running SSD benchmark..."
                taskProgress = 0.0
            }
            for step in 1...10 {
                if workItem.isCancelled { return }
                DispatchQueue.main.async {
                    taskProgress = Double(step) / 10.0
                }
                usleep(70_000)
            }
            guard !workItem.isCancelled else { return }
            let ssdResult = averageSSDMeasurement(repeatCount: benchmarkRepeatCount) {
                benchmark.measureSSDSpeed()
            }
            DispatchQueue.main.async {
                ssdScore = calibratedScore(title: "SSD Speed Score", rawScore: ssdResult.score)
                ssdRawCombinedMBps = ssdResult.combinedMBps.rounded()
                ssdRawReadMBps = ssdResult.readMBps.rounded()
                ssdRawWriteMBps = ssdResult.writeMBps.rounded()
                taskProgress = 1.0
                overallProgress = 0.80
            }

            // Graphics Benchmark
            DispatchQueue.main.async {
                progressMessage = "Running Graphics benchmark..."
                taskProgress = 0.0
            }
            for step in 1...10 {
                if workItem.isCancelled { return }
                DispatchQueue.main.async {
                    taskProgress = Double(step) / 10.0
                }
                usleep(70_000)
            }
            guard !workItem.isCancelled else { return }
            let graphicsResult = averageDoubleMeasurement(repeatCount: benchmarkRepeatCount) {
                benchmark.measureGraphicsRendering()
            }

            DispatchQueue.main.async {
                let rawMetrics = BenchmarkRawMetrics(
                    singleCore: singleCoreResult,
                    multiCore: cpuResult,
                    memory: memoryResult.score,
                    memoryThroughputMBps: memoryResult.throughputMBps,
                    ssd: ssdResult.score,
                    ssdCombinedMBps: ssdResult.combinedMBps,
                    ssdReadMBps: ssdResult.readMBps,
                    ssdWriteMBps: ssdResult.writeMBps,
                    graphics: graphicsResult
                )
                let backendUsed = benchmark.lastGraphicsBackendUsed.rawValue
                let validation = BenchmarkValidator.validate(
                    rawMetrics: rawMetrics,
                    intensity: benchmarkIntensity,
                    graphicsBackend: backendUsed,
                    thermalState: ProcessInfo.processInfo.thermalState.rawValue
                )
                let calibratedScores = BenchmarkScoreCalculator.calibratedScores(from: rawMetrics)
                let calibratedSingleCore = calibratedScores[.singleCore] ?? 0
                let calibratedCPU = calibratedScores[.multiCore] ?? 0
                let calibratedMemory = calibratedScores[.memory] ?? 0
                let calibratedSSD = calibratedScores[.ssd] ?? 0
                let calibratedGraphics = calibratedScores[.graphics] ?? 0
                let computedOverall = BenchmarkScoreCalculator.overallScore(from: calibratedScores)

                singleCoreScore = calibratedSingleCore
                cpuScore = calibratedCPU
                memoryScore = calibratedMemory
                ssdScore = calibratedSSD
                graphicsScore = calibratedGraphics
                memoryRawThroughputMBps = memoryResult.throughputMBps.rounded()
                ssdRawCombinedMBps = ssdResult.combinedMBps.rounded()
                ssdRawReadMBps = ssdResult.readMBps.rounded()
                ssdRawWriteMBps = ssdResult.writeMBps.rounded()
                overallScore = computedOverall.rounded()
                benchmarkValidationSummary = validation

                taskProgress = 1.0
                overallProgress = 1.0
                progressMessage = validation.shouldSave ? "Benchmark complete!" : "Benchmark finished, but this run was not saved."
                isRunning = false
                benchmarkComplete = true
                benchmarkFailedMessage = validation.shouldSave ? nil : validation.primaryMessage
                if validation.shouldSave {
                    Haptics.success()
                } else {
                    Haptics.warning()
                }

                if validation.shouldSave, let overall = overallScore {
                    let newResult = BenchmarkResult(
                        sessionID: UUID(),
                        deviceName: DeviceModel.currentDeviceName(),
                        benchmarkIntensity: benchmarkIntensity,
                        note: "",
                        tags: [],
                        isPinned: false,
                        singleCoreScore: calibratedSingleCore,
                        cpuScore: calibratedCPU,
                        memoryScore: calibratedMemory,
                        memoryRawThroughputMBps: memoryResult.throughputMBps.rounded(),
                        ssdScore: calibratedSSD,
                        ssdRawCombinedMBps: ssdResult.combinedMBps.rounded(),
                        ssdRawReadMBps: ssdResult.readMBps.rounded(),
                        ssdRawWriteMBps: ssdResult.writeMBps.rounded(),
                        graphicsBackend: backendUsed,
                        graphicsScore: calibratedGraphics,
                        rawSingleCoreScore: rawMetrics.singleCore,
                        rawMultiCoreScore: rawMetrics.multiCore,
                        rawMemoryScore: rawMetrics.memory,
                        rawSSDScore: rawMetrics.ssd,
                        rawGraphicsScore: rawMetrics.graphics,
                        overallScore: overall,
                        timestamp: Date(),
                        thermalState: ProcessInfo.processInfo.thermalState.rawValue,
                        wasConnectedToPower: currentPowerConnectionState(),
                        reliability: validation.reliability,
                        validationMessages: validation.messages
                    )
                    scores.append(newResult)
                    BenchmarkStorage.save(scores)
                }
            }
        }

        benchmarkTask = workItem
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }
    
    private func averageDoubleMeasurement(repeatCount: Int, block: () -> Double) -> Double {
        let count = max(repeatCount, 1)
        let values = (0..<count).map { _ in block() }
        return values.reduce(0, +) / Double(count)
    }

    private func averageMemoryMeasurement(repeatCount: Int, block: () -> (score: Double, throughputMBps: Double)) -> (score: Double, throughputMBps: Double) {
        let count = max(repeatCount, 1)
        let values = (0..<count).map { _ in block() }
        let score = values.map(\.score).reduce(0, +) / Double(count)
        let throughput = values.map(\.throughputMBps).reduce(0, +) / Double(count)
        return (score, throughput)
    }

    private func averageSSDMeasurement(repeatCount: Int, block: () -> (score: Double, combinedMBps: Double, readMBps: Double, writeMBps: Double)) -> (score: Double, combinedMBps: Double, readMBps: Double, writeMBps: Double) {
        let count = max(repeatCount, 1)
        let values = (0..<count).map { _ in block() }
        let score = values.map(\.score).reduce(0, +) / Double(count)
        let combined = values.map(\.combinedMBps).reduce(0, +) / Double(count)
        let read = values.map(\.readMBps).reduce(0, +) / Double(count)
        let write = values.map(\.writeMBps).reduce(0, +) / Double(count)
        return (score, combined, read, write)
    }
    
    private func summaryText(overallScore: Double) -> String {
        switch overallScore {
        case 850...:
            return "This looks like an elite-class run from current references."
        case 700..<850:
            return "This looks like a strong high-end run with well above average overall performance from current references."
        case 550..<700:
            return "This looks like an upper-mid to high-end result with solid all-round performance from current references."
        case 400..<550:
            return "This sits in the mid-range band from current references."
        default:
            return "This result sits in the entry to lower-mid range from current references."
        }
    }

    private func currentPowerConnectionState() -> Bool? {
        #if canImport(UIKit)
        let device = UIDevice.current
        let wasMonitoringEnabled = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true
        let state = device.batteryState
        device.isBatteryMonitoringEnabled = wasMonitoringEnabled

        switch state {
        case .charging, .full:
            return true
        case .unplugged:
            return false
        default:
            return nil
        }
        #else
        return nil
        #endif
    }

    func cancelBenchmark() {
        benchmarkTask?.cancel()
        isRunning = false
        benchmarkComplete = false
        benchmarkFailedMessage = nil
        benchmarkValidationSummary = nil
        progressMessage = "Benchmark cancelled."
        overallProgress = 0.0
        taskProgress = 0.0
    }

    func acknowledgeBenchmarkCompletion() {
        singleCoreScore = nil
        cpuScore = nil
        memoryScore = nil
        memoryRawThroughputMBps = nil
        ssdScore = nil
        ssdRawCombinedMBps = nil
        ssdRawReadMBps = nil
        ssdRawWriteMBps = nil
        graphicsScore = nil
        overallScore = nil
        benchmarkComplete = false
        benchmarkFailedMessage = nil
        benchmarkValidationSummary = nil
        progressMessage = "Ready to benchmark!"
        overallProgress = 0.0
        taskProgress = 0.0
    }

    func calibratedScore(title: String, rawScore: Double) -> Double {
        let metric: BenchmarkMetricKind

        switch title {
        case "Single-Core Score":
            metric = .singleCore
        case "Multi-Core Score":
            metric = .multiCore
        case "Memory Score":
            metric = .memory
        case "SSD Speed Score":
            metric = .ssd
        case "Graphics Score":
            metric = .graphics
        default:
            metric = .singleCore
        }

        return BenchmarkScoreCalculator.calibratedScore(metric: metric, rawValue: rawScore)
    }

    func metricColor(title: String, score: Double) -> Color {
        switch title {
        case "Single-Core Score":
            if score >= 500 { return .green }
            if score >= 380 { return .yellow }
            return .red

        case "Multi-Core Score":
            if score >= 1150 { return .green }
            if score >= 800 { return .yellow }
            return .red

        case "Memory Score":
            if score >= 130 { return .green }
            if score >= 85 { return .yellow }
            return .red

        case "SSD Speed Score":
            if score >= 800 { return .green }
            if score >= 500 { return .yellow }
            return .red

        case "Graphics Score":
            if score >= 950 { return .green }
            if score >= 650 { return .yellow }
            return .red

        case "Overall Score":
            if score >= 700 { return .green }
            if score >= 500 { return .yellow }
            return .red

        default:
            if score >= 600 { return .green }
            if score >= 300 { return .yellow }
            return .red
        }
    }
}

// MARK: - Glass Card Modifier
private struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(BencherTheme.cardGradient)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

private extension View {
    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - History View
struct HistoryView: View {
    @Binding var scores: [BenchmarkResult]
    @Binding var pendingAction: DashboardHistoryAction?
    @Binding var pendingSelectedResultID: BenchmarkResult.ID?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedResultID: BenchmarkResult.ID?
    @State private var isShowingExporter: Bool = false
    @State private var isShowingImporter: Bool = false
    @State private var exportDocument = BenchmarkHistoryDocument(results: [])
    @State private var historyTransferMessage: String? = nil
    @State private var isShowingTransferAlert: Bool = false
    @State private var sortOption: HistorySortOption = .dateNewest
    @State private var isShowingCompareSheet: Bool = false
    @State private var compareSelection: Set<BenchmarkResult.ID> = []
    @State private var compareResults: [BenchmarkResult] = []
    @State private var isShowingComparison: Bool = false
    @State private var compactComparisonSession: ComparisonSession? = nil
    @State private var pendingComparisonResults: [BenchmarkResult] = []
    @State private var shouldPresentPendingComparison: Bool = false
    @State private var exportCSVDocument = BenchmarkHistoryCSVDocument(results: [])
    @AppStorage("preferredExportFormat") private var preferredExportFormat: String = "JSON"
    @State private var isShowingCSVExporter: Bool = false
    @State private var exportShareItem: ExportShareItem? = nil
    @State private var historySearchText: String = ""
    @State private var selectedDeviceHistoryFilter: String = "All Devices"
    @State private var selectedBenchmarkHistoryFilter: String = "All Intensities"
    @State private var selectedThermalHistoryFilter: String = "All Thermal States"
    @State private var selectedPowerHistoryFilter: String = "All Power States"
    @State private var selectedGraphicsHistoryFilter: String = "All Graphics Paths"
    @State private var favouritesOnly: Bool = false
    @State private var historyFilterScrollIndex: Int = 0
    @State private var isShowingDeleteAllConfirmation: Bool = false
    @State private var isShowingMultiDeleteSheet: Bool = false
    @State private var recentlyDeletedResults: [BenchmarkResult] = []
    @State private var isShowingMetadataEditor: Bool = false
    @State private var draftNote: String = ""
    @State private var draftTagsText: String = ""
    @State private var isPreparingExport: Bool = false
    @State private var isShowingExportOptions: Bool = false
    @State private var latestCompletedResult: BenchmarkResult? = nil
    @State private var compactPresentedResult: BenchmarkResult? = nil
    private var sortedScores: [BenchmarkResult] {
        switch sortOption {
        case .dateNewest:
            return scores.sorted(by: { $0.timestamp > $1.timestamp })
        case .dateOldest:
            return scores.sorted(by: { $0.timestamp < $1.timestamp })
        case .scoreHighest:
            return scores.sorted(by: { $0.overallScore > $1.overallScore })
        case .scoreLowest:
            return scores.sorted(by: { $0.overallScore < $1.overallScore })
        }
    }
    
    private var filteredSortedScores: [BenchmarkResult] {
        sortedScores.filter { result in
            let matchesSearch = historySearchText.isEmpty
                || result.deviceName.localizedCaseInsensitiveContains(historySearchText)
                || result.note.localizedCaseInsensitiveContains(historySearchText)
                || result.tags.joined(separator: ", ").localizedCaseInsensitiveContains(historySearchText)

            let matchesDevice = selectedDeviceHistoryFilter == "All Devices" || result.deviceName == selectedDeviceHistoryFilter
            let matchesBenchmark = selectedBenchmarkHistoryFilter == "All Intensities" || result.benchmarkIntensity == selectedBenchmarkHistoryFilter
            let matchesThermal = selectedThermalHistoryFilter == "All Thermal States" || thermalStateText(result.thermalState) == selectedThermalHistoryFilter
            let matchesPower = selectedPowerHistoryFilter == "All Power States" || powerConnectionText(result.wasConnectedToPower) == selectedPowerHistoryFilter
            let matchesGraphics = selectedGraphicsHistoryFilter == "All Graphics Paths" || result.graphicsBackend == selectedGraphicsHistoryFilter
            let matchesFavourite = !favouritesOnly || result.isPinned

            return matchesSearch && matchesDevice && matchesBenchmark && matchesThermal && matchesPower && matchesGraphics && matchesFavourite
        }
    }

    private var historyDevices: [String] {
        ["All Devices"] + Array(Set(scores.map { $0.deviceName })).sorted()
    }

    private var historyBenchmarkIntensities: [String] {
        ["All Intensities", "Balanced", "Light", "Extreme"]
    }

    private var historyThermalFilters: [String] {
        ["All Thermal States", "Nominal", "Fair", "Serious", "Critical", "Unknown"]
    }

    private var historyPowerFilters: [String] {
        ["All Power States", "On AC Power", "Not on AC Power", "Unknown"]
    }

    private var historyGraphicsFilters: [String] {
        ["All Graphics Paths"] + Array(Set(scores.map(\.graphicsBackend))).sorted()
    }

    private var selectedResult: BenchmarkResult? {
        guard let selectedResultID else { return filteredSortedScores.first }
        return filteredSortedScores.first(where: { $0.id == selectedResultID }) ?? filteredSortedScores.first
    }
    
    private func comparisonBase(for result: BenchmarkResult) -> BenchmarkResult? {
        comparableBenchmarkBaseline(for: result, within: scores)
    }

    var body: some View {
        historyContainer
            .searchable(text: $historySearchText, prompt: "Search devices, notes or tags")
            .onChange(of: pendingAction) { _, newValue in
                guard let newValue else { return }
                handlePendingDashboardAction(newValue)
                pendingAction = nil
            }
            .onChange(of: pendingSelectedResultID) { _, newValue in
                guard let newValue else { return }
                openHistoryResult(withID: newValue)
                pendingSelectedResultID = nil
            }
            .bencherItemCover(item: $compactPresentedResult) { result in
                NavigationStack {
                    ScrollView {
                        DetailedResultView(result: result, comparisonBase: comparisonBase(for: result))
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }
                    .bencherInlineTitleDisplayMode()
                    .toolbar {
                        ToolbarItem(placement: .bencherTopBarTrailing) {
                            Button("Done") {
                                compactPresentedResult = nil
                            }
                        }
                    }
                }
            }
            .sheet(item: $exportShareItem) { item in
                ActivityView(activityItems: [item.url])
            }
            .sheet(isPresented: $isShowingMetadataEditor) {
                MetadataEditorView(
                    note: $draftNote,
                    tagsText: $draftTagsText,
                    onSave: saveMetadata
                )
            }.sheet(isPresented: $isShowingMultiDeleteSheet) {
                MultiDeleteHistoryView(scores: scores) { idsToDelete in
                    recentlyDeletedResults = scores.filter { idsToDelete.contains($0.id) }
                    scores.removeAll { idsToDelete.contains($0.id) }
                    BenchmarkStorage.save(scores)

                    if let selectedResultID, idsToDelete.contains(selectedResultID) {
                        self.selectedResultID = filteredSortedScores.first?.id
                    }

                    isShowingMultiDeleteSheet = false
                }
            }
            .fileExporter(
                isPresented: $isShowingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "BencherHistory"
            ) { result in
                switch result {
                case .success:
                    historyTransferMessage = "History exported successfully."
                    isShowingTransferAlert = true
                case .failure(let error):
                    historyTransferMessage = "Export failed: \(error.localizedDescription)"
                    isShowingTransferAlert = true
                }
            }
            .fileExporter(
                isPresented: $isShowingCSVExporter,
                document: exportCSVDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "BencherHistory"
            ) { result in
                switch result {
                case .success:
                    historyTransferMessage = "History exported successfully."
                    isShowingTransferAlert = true
                case .failure(let error):
                    historyTransferMessage = "Export failed: \(error.localizedDescription)"
                    isShowingTransferAlert = true
                }
            }
            .fileImporter(
                isPresented: $isShowingImporter,
                allowedContentTypes: [.json, .commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else {
                        historyTransferMessage = "Import failed: No file selected."
                        isShowingTransferAlert = true
                        return
                    }
                    importHistory(from: url)
                case .failure(let error):
                    historyTransferMessage = "Import failed: \(error.localizedDescription)"
                    isShowingTransferAlert = true
                }
            }
            .alert("History Transfer", isPresented: $isShowingTransferAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(historyTransferMessage ?? "No message available.")
            })
            .alert("Delete All History", isPresented: $isShowingDeleteAllConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllHistory()
                }
            } message: {
                Text("This will permanently remove all saved benchmark history.")
            }
            .confirmationDialog("Choose export range", isPresented: $isShowingExportOptions, titleVisibility: .visible) {
                ForEach(availableExportCounts, id: \.self) { count in
                    let label = exportLabel(for: count)
                    Button(label) {
                        prepareExport(limit: count)
                    }
                }
            } message: {
                Text("Choose how many saved results you want to export.")
            }
            .sheet(isPresented: $isShowingCompareSheet, onDismiss: {
                if horizontalSizeClass == .compact, shouldPresentPendingComparison, pendingComparisonResults.count == 2 {
                    let resultsToPresent = pendingComparisonResults
                    shouldPresentPendingComparison = false
                    pendingComparisonResults = []

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        compactComparisonSession = ComparisonSession(results: resultsToPresent)
                    }
                }
            }) {
                CompareSelectionView(
                    scores: sortedScores,
                    selectedIDs: $compareSelection,
                    onComplete: { results in
                        if horizontalSizeClass == .compact {
                            pendingComparisonResults = results
                            shouldPresentPendingComparison = true
                        } else {
                            compareResults = results
                            isShowingComparison = true
                        }
                    }
                )
                #if os(macOS)
                .frame(minWidth: 640, minHeight: 720)
                #endif
            }
            .bencherItemCover(item: $compactComparisonSession) { session in
                NavigationStack {
                    CompareResultsView(
                        results: session.results,
                        onClose: {
                            compactComparisonSession = nil
                            compareResults = []
                            pendingComparisonResults = []
                            shouldPresentPendingComparison = false
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .bencherTopBarLeading) {
                            Button("Done") {
                                compactComparisonSession = nil
                                compareResults = []
                                pendingComparisonResults = []
                                shouldPresentPendingComparison = false
                            }
                        }
                    }
                }
            }
            .onAppear {
                if selectedResultID == nil {
                    selectedResultID = sortedScores.first?.id
                }
            }
            .onChange(of: scores) { _, newScores in
                let newSorted = newScores.sorted(by: { $0.timestamp > $1.timestamp })
                if let selectedResultID,
                   newSorted.contains(where: { $0.id == selectedResultID }) {
                    return
                }
                self.selectedResultID = newSorted.first?.id
            }
    }

    @ViewBuilder
    private var historyContainer: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            historySidebarContent
                .frame(minWidth: 280, idealWidth: 300, maxWidth: 340)
                .background(BencherPlatformColors.systemBackground)
                .clipped()

            Divider()

            historyDetailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .toolbar {
            historyActionsToolbar
        }
        #else
        NavigationSplitView {
            historySidebarContent
                .navigationTitle("")
                .toolbar {
                    historyActionsToolbar
                }
        } detail: {
            historyDetailContent
        }
        #endif
    }

    @ToolbarContentBuilder
    private var historyActionsToolbar: some ToolbarContent {
        ToolbarItem(placement: .bencherTopBarTrailing) {
            Menu {
                Section("Actions") {
                    Button {
                        openMetadataEditor()
                    } label: {
                        Label("Edit Notes & Tags", systemImage: "pencil.and.list.clipboard")
                    }
                    .disabled(selectedResult == nil)

                    Button {
                        presentHistoryImporter()
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }

                    Button {
                        presentMultiDelete()
                    } label: {
                        Label("Multi-Delete", systemImage: "checklist")
                    }
                    .disabled(sortedScores.isEmpty)
                }

                Section {
                    Button(role: .destructive) {
                        presentDeleteAllConfirmation()
                    } label: {
                        Label("Delete All History", systemImage: "trash")
                    }
                    .disabled(sortedScores.isEmpty)
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }

    private var historySidebarContent: some View {
        List {
            Section {
                HStack(alignment: .center, spacing: 8) {
                    Text("History")
                        .font(horizontalSizeClass == .compact ? .title.bold() : .title.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 6)

                    Button {
                        launchCompareFlow()
                    } label: {
                        if horizontalSizeClass == .compact {
                            Image(systemName: "rectangle.split.2x1")
                                .font(.headline)
                                .frame(width: 34, height: 34)
                        } else {
                            HStack(spacing: 5) {
                                Image(systemName: "rectangle.split.2x1")
                                Text("Compare")
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .font(.caption.weight(.semibold))
                            .frame(height: 30)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(filteredSortedScores.count < 2)

                    Button {
                        if !sortedScores.isEmpty {
                            isShowingExportOptions = true
                        } else {
                            historyTransferMessage = "There are no benchmark results to export yet."
                            isShowingTransferAlert = true
                        }
                    } label: {
                        if horizontalSizeClass == .compact {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                                .frame(width: 34, height: 34)
                        } else {
                            HStack(spacing: 5) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .font(.caption.weight(.semibold))
                            .frame(height: 30)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(sortedScores.isEmpty || isPreparingExport)
                }
                .padding(.top, horizontalSizeClass == .compact ? 0 : 4)

                Picker("Sort", selection: $sortOption) {
                    ForEach(HistorySortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(horizontalSizeClass == .compact ? .small : .regular)

                historySecondaryFiltersRow

                if !recentlyDeletedResults.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundColor(.blue)

                        Text(
                            recentlyDeletedResults.count == 1
                            ? "Last deleted history item can be restored."
                            : "Last deleted set of \(recentlyDeletedResults.count) history items can be restored."
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        Spacer()

                        Button("Undo") {
                            restoreRecentlyDeleted()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            if filteredSortedScores.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.system(size: 34))
                            .foregroundColor(.secondary)

                        Text("No matching history")
                            .font(.headline)

                        Text("Try clearing your search filters or running a benchmark.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredSortedScores) { result in
                    historyRowCard(for: result)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteResult(result)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                togglePinned(result)
                            } label: {
                                Label(result.isPinned ? "Unfavourite" : "Favourite", systemImage: result.isPinned ? "star.slash" : "star")
                            }
                            .tint(.yellow)
                        }
                }
            }
        }
        .listStyle(.plain)
    }

    private var historyDetailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let historyTransferMessage {
                    if isPreparingExport {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)

                            Text("Preparing export...")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)

                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.purple.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Text(historyTransferMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            self.historyTransferMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if horizontalSizeClass != .compact, isShowingComparison, compareResults.count == 2 {
                    CompareResultsView(
                        results: compareResults,
                        onClose: {
                            isShowingComparison = false
                            compareResults = []
                        }
                    )
                } else if let result = selectedResult {
                    DetailedResultView(result: result, comparisonBase: comparisonBase(for: result))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.system(size: 42))
                            .foregroundColor(.secondary)
                        Text("Select a benchmark run to view details")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var historySecondaryFiltersRow: some View {
        #if os(macOS)
        ScrollViewReader { proxy in
            HStack(spacing: 8) {
                historyFilterScrollButton(systemImage: "chevron.left", isEnabled: historyFilterScrollIndex > 0) {
                    scrollHistoryFilters(by: -1, proxy: proxy)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    historySecondaryFilterChips
                }

                historyFilterScrollButton(
                    systemImage: "chevron.right",
                    isEnabled: historyFilterScrollIndex < historyFilterChipIDs.count - 1
                ) {
                    scrollHistoryFilters(by: 1, proxy: proxy)
                }
            }
        }
        #else
        ScrollView(.horizontal, showsIndicators: false) {
            historySecondaryFilterChips
        }
        #endif
    }

    private var historySecondaryFilterChips: some View {
        HStack(spacing: horizontalSizeClass == .compact ? 8 : 10) {
            Menu {
                ForEach(historyDevices, id: \.self) { device in
                    Button {
                        selectedDeviceHistoryFilter = device
                    } label: {
                        historyMenuLabel(title: device, isSelected: selectedDeviceHistoryFilter == device)
                    }
                }
            } label: {
                filterChip(title: selectedDeviceHistoryFilter, systemImage: "iphone")
            }
            .id(HistoryFilterChipID.device)

            Menu {
                ForEach(historyBenchmarkIntensities, id: \.self) { intensity in
                    Button {
                        selectedBenchmarkHistoryFilter = intensity
                    } label: {
                        historyMenuLabel(title: intensity, isSelected: selectedBenchmarkHistoryFilter == intensity)
                    }
                }
            } label: {
                filterChip(title: selectedBenchmarkHistoryFilter, systemImage: "dial.medium")
            }
            .id(HistoryFilterChipID.intensity)

            Menu {
                ForEach(historyThermalFilters, id: \.self) { thermal in
                    Button {
                        selectedThermalHistoryFilter = thermal
                    } label: {
                        historyMenuLabel(title: thermal, isSelected: selectedThermalHistoryFilter == thermal)
                    }
                }
            } label: {
                filterChip(title: selectedThermalHistoryFilter, systemImage: "thermometer.medium")
            }
            .id(HistoryFilterChipID.thermal)

            Menu {
                ForEach(historyPowerFilters, id: \.self) { power in
                    Button {
                        selectedPowerHistoryFilter = power
                    } label: {
                        historyMenuLabel(title: power, isSelected: selectedPowerHistoryFilter == power)
                    }
                }
            } label: {
                filterChip(title: selectedPowerHistoryFilter, systemImage: "powerplug")
            }
            .id(HistoryFilterChipID.power)

            Menu {
                ForEach(historyGraphicsFilters, id: \.self) { backend in
                    Button {
                        selectedGraphicsHistoryFilter = backend
                    } label: {
                        historyMenuLabel(title: backend, isSelected: selectedGraphicsHistoryFilter == backend)
                    }
                }
            } label: {
                filterChip(title: selectedGraphicsHistoryFilter, systemImage: "display")
            }
            .id(HistoryFilterChipID.graphics)

            Button {
                favouritesOnly.toggle()
            } label: {
                filterChip(
                    title: favouritesOnly ? "Favourites" : "All Runs",
                    systemImage: favouritesOnly ? "star.fill" : "star"
                )
            }
            .buttonStyle(.plain)
            .id(HistoryFilterChipID.favourites)
        }
    }

    private var historyFilterChipIDs: [HistoryFilterChipID] {
        HistoryFilterChipID.allCases
    }

    private func scrollHistoryFilters(by offset: Int, proxy: ScrollViewProxy) {
        let newIndex = min(max(historyFilterScrollIndex + offset, 0), historyFilterChipIDs.count - 1)
        guard newIndex != historyFilterScrollIndex else { return }

        historyFilterScrollIndex = newIndex
        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(historyFilterChipIDs[newIndex], anchor: .center)
        }
    }

    @ViewBuilder
    private func historyFilterScrollButton(systemImage: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .foregroundColor(isEnabled ? .secondary : .gray)
        .opacity(isEnabled ? 1.0 : 0.45)
        .disabled(!isEnabled)
    }
    
    @ViewBuilder
    private func historyRowCard(for result: BenchmarkResult) -> some View {
        let isSelected = usesInlineHistoryDetail && selectedResultID == result.id
        let isCompact = usesModalHistoryDetail
        let scoreText = String(format: "%.0f", result.overallScore)
        let dateText = result.timestamp.formatted(date: .abbreviated, time: .shortened)
        let ramText = "RAM raw: \(String(format: "%.0f", result.memoryRawThroughputMBps)) MB/s"
        let ssdText = "SSD raw R/W: \(String(format: "%.0f", result.ssdRawReadMBps))/\(String(format: "%.0f", result.ssdRawWriteMBps)) MB/s"
        let latestFilteredResult = filteredSortedScores.max(by: { $0.timestamp < $1.timestamp })
        let isLatest = result.id == latestFilteredResult?.id
        let bestForDevice = scores.filter { $0.deviceName == result.deviceName }.max(by: { $0.overallScore < $1.overallScore })
        let isBestForDevice = bestForDevice?.id == result.id

        let card = VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(scoreText)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)

                    Text("Overall Score")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    if result.isPinned {
                        historyStatusChip(title: "Favourite", systemImage: "star.fill", tint: .yellow)
                    }
                    if isLatest {
                        historyStatusChip(title: "Latest", systemImage: "clock.fill", tint: .green)
                    }
                    if isBestForDevice {
                        historyStatusChip(title: "Best", systemImage: "trophy.fill", tint: .orange)
                    }

                    historyStatusChip(
                        title: result.benchmarkIntensity,
                        systemImage: "dial.medium",
                        tint: .blue
                    )

                    historyStatusChip(
                        title: result.graphicsBackend,
                        systemImage: "display",
                        tint: .pink
                    )
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "iphone")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(result.deviceName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(dateText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }

            if !result.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(result.tags, id: \.self) { tag in
                            historyTagChip(tag)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    smallMetricPill(title: "SC", value: result.singleCoreScore)
                    smallMetricPill(title: "MC", value: result.cpuScore)
                    smallMetricPill(title: "MEM", value: result.memoryScore)
                }
                HStack(spacing: 10) {
                    smallMetricPill(title: "SSD", value: result.ssdScore)
                    smallMetricPill(title: "GPU", value: result.graphicsScore)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(ramText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(ssdText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if result.thermalState > 0 {
                historyStatusChip(
                    title: "Thermals: \(thermalStateText(result.thermalState))",
                    systemImage: "thermometer.medium",
                    tint: .orange
                )
            } else {
                historyStatusChip(
                    title: "Thermals: Nominal",
                    systemImage: "checkmark.circle.fill",
                    tint: .green
                )
            }

            if let wasConnectedToPower = result.wasConnectedToPower {
                historyStatusChip(
                    title: wasConnectedToPower ? "Power: AC" : "Power: Battery",
                    systemImage: wasConnectedToPower ? "powerplug" : "battery.50",
                    tint: wasConnectedToPower ? .blue : .gray
                )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isSelected ? Color.blue.opacity(0.35) : Color.primary.opacity(0.06),
                    lineWidth: isSelected ? 1.6 : 1
                )
        )
        .shadow(
            color: isSelected ? Color.blue.opacity(0.12) : Color.clear,
            radius: isSelected ? 10 : 0,
            x: 0,
            y: 0
        )
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .listRowBackground(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? Color.blue.opacity(0.06) : Color.clear)
                .padding(.vertical, 4)
        )

        card
            .onTapGesture {
                if isCompact {
                    compactPresentedResult = result
                } else {
                    selectedResultID = result.id
                }
            }
    }
    
    private func openHistoryResult(withID id: BenchmarkResult.ID) {
        historySearchText = ""
        selectedDeviceHistoryFilter = "All Devices"
        selectedBenchmarkHistoryFilter = "All Intensities"
        selectedThermalHistoryFilter = "All Thermal States"
        selectedPowerHistoryFilter = "All Power States"
        selectedGraphicsHistoryFilter = "All Graphics Paths"
        favouritesOnly = false

        guard let matched = scores.first(where: { $0.id == id }) else { return }
        selectedResultID = matched.id

        if usesModalHistoryDetail {
            compactPresentedResult = matched
        }
    }

    private var usesInlineHistoryDetail: Bool {
        #if os(macOS)
        true
        #else
        horizontalSizeClass != .compact
        #endif
    }

    private var usesModalHistoryDetail: Bool {
        !usesInlineHistoryDetail
    }
    
    private func launchCompareFlow() {
        if sortedScores.count >= 2 {
            compareSelection = []
            compareResults = []
            pendingComparisonResults = []
            shouldPresentPendingComparison = false
            isShowingComparison = false
            compactComparisonSession = nil
            isShowingCompareSheet = true
        } else {
            historyTransferMessage = "You need at least two benchmark results to compare."
            isShowingTransferAlert = true
        }
    }

    private func handlePendingDashboardAction(_ action: DashboardHistoryAction) {
        switch action {
        case .compare:
            launchCompareFlow()
        case .export:
            if !sortedScores.isEmpty {
                isShowingExportOptions = true
            } else {
                historyTransferMessage = "There are no benchmark results to export yet."
                isShowingTransferAlert = true
            }
        }
    }
    
    private func openMetadataEditor() {
        guard let result = selectedResult else { return }
        draftNote = result.note
        draftTagsText = result.tags.joined(separator: ", ")
        isShowingMetadataEditor = true
    }

    private func saveMetadata() {
        guard let selectedResultID,
              let index = scores.firstIndex(where: { $0.id == selectedResultID }) else {
            isShowingMetadataEditor = false
            return
        }

        let parsedTags = draftTagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let existing = scores[index]
        scores[index] = BenchmarkResult(
            id: existing.id,
            sessionID: existing.sessionID,
            deviceName: existing.deviceName,
            benchmarkIntensity: existing.benchmarkIntensity,
            note: draftNote,
            tags: parsedTags,
            isPinned: existing.isPinned,
            singleCoreScore: existing.singleCoreScore,
            cpuScore: existing.cpuScore,
            memoryScore: existing.memoryScore,
            memoryRawThroughputMBps: existing.memoryRawThroughputMBps,
            ssdScore: existing.ssdScore,
            ssdRawCombinedMBps: existing.ssdRawCombinedMBps,
            ssdRawReadMBps: existing.ssdRawReadMBps,
            ssdRawWriteMBps: existing.ssdRawWriteMBps,
            graphicsBackend: existing.graphicsBackend,
            graphicsScore: existing.graphicsScore,
            overallScore: existing.overallScore,
            timestamp: existing.timestamp,
            thermalState: existing.thermalState,
            wasConnectedToPower: existing.wasConnectedToPower
        )

        BenchmarkStorage.save(scores)
        isShowingMetadataEditor = false
    }

    private var availableExportCounts: [Int?] {
        var options: [Int?] = [1]
        let thresholds = [5, 10, 15, 20]

        for threshold in thresholds where sortedScores.count >= threshold {
            options.append(threshold)
        }

        if sortedScores.count > 1 {
            options.append(nil)
        }

        return options
    }

    private func exportLabel(for count: Int?) -> String {
        if let count {
            return count == 1 ? "Export last 1 result" : "Export last \(count) results"
        }
        return "Export all results"
    }

    private nonisolated func writeExportFile(results: [BenchmarkResult], preferredFormat: String) throws -> URL {
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let fileExtension = preferredFormat == "CSV" ? "csv" : "json"
        let fileName = "BencherHistory-\(timestamp).\(fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let data: Data
        if preferredFormat == "CSV" {
            data = BenchmarkHistoryCSVDocument.exportData(for: results)
        } else {
            let encoder = JSONEncoder()
            data = try encoder.encode(results)
        }

        try data.write(to: url, options: .atomic)
        return url
    }
    
    private func restoreRecentlyDeleted() {
        guard !recentlyDeletedResults.isEmpty else { return }

        let existingIDs = Set(scores.map { $0.id })
        let toRestore = recentlyDeletedResults.filter { !existingIDs.contains($0.id) }

        guard !toRestore.isEmpty else {
            recentlyDeletedResults = []
            Haptics.success()
            return
        }

        scores.append(contentsOf: toRestore)
        BenchmarkStorage.save(scores)

        if selectedResultID == nil {
            selectedResultID = sortedScores.first?.id
        }

        recentlyDeletedResults = []
    }
    
    private func togglePinned(_ result: BenchmarkResult) {
        guard let index = scores.firstIndex(where: { $0.id == result.id }) else { return }

        let existing = scores[index]
        scores[index] = BenchmarkResult(
            id: existing.id,
            sessionID: existing.sessionID,
            deviceName: existing.deviceName,
            benchmarkIntensity: existing.benchmarkIntensity,
            note: existing.note,
            tags: existing.tags,
            isPinned: !existing.isPinned,
            singleCoreScore: existing.singleCoreScore,
            cpuScore: existing.cpuScore,
            memoryScore: existing.memoryScore,
            memoryRawThroughputMBps: existing.memoryRawThroughputMBps,
            ssdScore: existing.ssdScore,
            ssdRawCombinedMBps: existing.ssdRawCombinedMBps,
            ssdRawReadMBps: existing.ssdRawReadMBps,
            ssdRawWriteMBps: existing.ssdRawWriteMBps,
            graphicsBackend: existing.graphicsBackend,
            graphicsScore: existing.graphicsScore,
            overallScore: existing.overallScore,
            timestamp: existing.timestamp,
            thermalState: existing.thermalState,
            wasConnectedToPower: existing.wasConnectedToPower
        )

        BenchmarkStorage.save(scores)
    }

    private func deleteAllHistory() {
        recentlyDeletedResults = scores
        scores.removeAll()
        BenchmarkStorage.save(scores)
        selectedResultID = nil
        compareResults = []
        compareSelection = []
        pendingComparisonResults = []
        shouldPresentPendingComparison = false
        isShowingComparison = false
        compactComparisonSession = nil
    }

    private func deleteResult(_ result: BenchmarkResult) {
        recentlyDeletedResults = [result]
        scores.removeAll { $0.id == result.id }
        BenchmarkStorage.save(scores)

        if selectedResultID == result.id {
            selectedResultID = sortedScores.first?.id
        }

        if compareResults.contains(where: { $0.id == result.id }) {
            compareResults = []
            isShowingComparison = false
            compactComparisonSession = nil
            pendingComparisonResults = []
            shouldPresentPendingComparison = false
        }

        compareSelection.remove(result.id)
    }

    private func prepareExport(limit: Int?) {
        isPreparingExport = true

        let resultsToExport: [BenchmarkResult]
        if let limit {
            resultsToExport = Array(sortedScores.prefix(limit))
        } else {
            resultsToExport = sortedScores
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let url = try writeExportFile(results: resultsToExport, preferredFormat: preferredExportFormat)
                DispatchQueue.main.async {
                    exportShareItem = ExportShareItem(url: url)
                    isPreparingExport = false
                    Haptics.light()
                }
            } catch {
                DispatchQueue.main.async {
                    historyTransferMessage = "Export failed: \(error.localizedDescription)"
                    isShowingTransferAlert = true
                    isPreparingExport = false
                    Haptics.error()
                }
            }
        }
    }
    private func thermalStateText(_ state: Int) -> String {
        switch state {
        case 0:
            return "Nominal"
        case 1:
            return "Fair"
        case 2:
            return "Serious"
        case 3:
            return "Critical"
        default:
            return "Unknown"
        }
    }

    private func powerConnectionText(_ state: Bool?) -> String {
        guard let state else { return "Unknown" }
        return state ? "On AC Power" : "Not on AC Power"
    }

    private func presentHistoryImporter() {
        DispatchQueue.main.async {
            isShowingImporter = true
        }
    }

    private func presentMultiDelete() {
        DispatchQueue.main.async {
            isShowingMultiDeleteSheet = true
        }
    }

    private func presentDeleteAllConfirmation() {
        DispatchQueue.main.async {
            isShowingDeleteAllConfirmation = true
        }
    }

    private func importHistory(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let fileExtension = url.pathExtension.lowercased()

            let imported: [BenchmarkResult]
            if fileExtension == "csv" || fileExtension == "txt" {
                imported = try BenchmarkHistoryCSVDocument.parseCSV(data)
            } else {
                imported = try JSONDecoder().decode([BenchmarkResult].self, from: data)
            }

            let existingIDs = Set(scores.map { $0.id })
            let merged = BenchmarkStorage.mergeForImport(existing: scores, imported: imported)
            let addedCount = imported.filter { !existingIDs.contains($0.id) }.count
            let ignoredCount = imported.count - addedCount

            scores = merged
            BenchmarkStorage.save(merged)
            selectedResultID = merged.first?.id

            historyTransferMessage = "Import complete: added \(addedCount) new result\(addedCount == 1 ? "" : "s") and ignored \(ignoredCount) duplicate result\(ignoredCount == 1 ? "" : "s")."
            isShowingTransferAlert = true
            Haptics.success()
        } catch {
            historyTransferMessage = "Import failed: \(error.localizedDescription)"
            isShowingTransferAlert = true
            Haptics.error()
        }
    }

    @ViewBuilder
    private func filterChip(title: String, systemImage: String) -> some View {
        HStack(spacing: horizontalSizeClass == .compact ? 5 : 6) {
            Image(systemName: systemImage)
                .font(horizontalSizeClass == .compact ? .caption2 : .caption)
            Text(title)
                .font((horizontalSizeClass == .compact ? Font.caption2 : Font.caption).weight(.semibold))
                .lineLimit(1)
        }
        .foregroundColor(.primary)
        .padding(.horizontal, horizontalSizeClass == .compact ? 8 : 10)
        .padding(.vertical, horizontalSizeClass == .compact ? 6 : 7)
        .background(BencherTheme.accentChipGradient)
        .clipShape(Capsule())
    }

    private func historyMenuLabel(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
    
    @ViewBuilder
    private func historyStatusChip(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption2)

            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func historyTagChip(_ tag: String) -> some View {
        Text(tag)
            .font(.caption.weight(.semibold))
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.08))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func smallMetricPill(title: String, value: Double) -> some View {
        Text("\(title) \(String(format: "%.0f", value))")
            .font(.caption.weight(.semibold))
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

// MARK: - Detailed Result View
struct DetailedResultView: View {
    let result: BenchmarkResult
    let comparisonBase: BenchmarkResult?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Benchmark Details")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Upgraded summary card
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(format: "%.0f", result.overallScore))
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.blue)

                        Text("Overall Score")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        if result.isPinned {
                            detailStatusChip(title: "Favourite", systemImage: "star.fill", tint: .yellow)
                        }

                        detailStatusChip(title: result.benchmarkIntensity, systemImage: "dial.medium", tint: .blue)
                        detailStatusChip(title: result.graphicsBackend, systemImage: "display", tint: .pink)

                        detailStatusChip(
                            title: thermalStateText(result.thermalState),
                            systemImage: result.thermalState > 0 ? "thermometer.medium" : "checkmark.circle.fill",
                            tint: result.thermalState > 0 ? .orange : .green
                        )

                        detailStatusChip(
                            title: powerConnectionText(result.wasConnectedToPower),
                            systemImage: result.wasConnectedToPower == true ? "powerplug.fill" : "battery.50",
                            tint: result.wasConnectedToPower == true ? .blue : (result.wasConnectedToPower == false ? .secondary : .gray)
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "iphone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(result.deviceName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(result.timestamp.formatted(date: .complete, time: .standard))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Session: \(result.sessionID.uuidString.prefix(8))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: result.wasConnectedToPower == true ? "powerplug" : "battery.50")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(powerConnectionText(result.wasConnectedToPower))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if result.thermalState > 0 {
                    Text("This run may have been affected because your device was getting too warm.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.orange)
                }

                if let validationMessage = result.validationMessages.first {
                    benchmarkComparisonNotice(validationMessage)
                }

                if let comparisonWarningText {
                    benchmarkComparisonNotice(comparisonWarningText)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)

            ResultMetricView(
                title: "Single-Core Score",
                value: result.singleCoreScore,
                description: "Measures how fast your device handles work on a single core. Higher scores usually mean snappier everyday performance for things like browsing, opening apps and lighter games.",
                deltaText: deltaText(current: result.singleCoreScore, previous: comparisonBase?.singleCoreScore)
            )

            ResultMetricView(
                title: "Multi-Core Score",
                value: result.cpuScore,
                description: "Measures how well your processor handles heavier work spread across multiple cores. Higher scores usually mean better performance in demanding tasks like video editing, larger workloads and more intensive games.",
                deltaText: deltaText(current: result.cpuScore, previous: comparisonBase?.cpuScore)
            )

            ResultMetricView(
                title: "Memory Score",
                value: result.memoryScore,
                description:
                    Text(.init("Measures how quickly your device can move and process data in memory. Higher scores usually help with heavier multitasking, large creative apps and other memory-hungry work. Raw throughput: \(String(format: "%.0f", result.memoryRawThroughputMBps)) MB/s.")),
                deltaText: deltaText(current: result.memoryScore, previous: comparisonBase?.memoryScore)
            )

            ResultMetricView(
                title: "SSD Speed Score",
                value: result.ssdScore,
                description: "Measures how quickly your device can read and write temporary files to local storage. Higher scores usually mean faster app launches, snappier file-heavy work and better performance in storage-intensive tasks. Raw combined speed: \(String(format: "%.0f", result.ssdRawCombinedMBps)) MB/s. Raw read/write: \(String(format: "%.0f", result.ssdRawReadMBps))/\(String(format: "%.0f", result.ssdRawWriteMBps)) MB/s.",
                deltaText: deltaText(current: result.ssdScore, previous: comparisonBase?.ssdScore)
            )

            ResultMetricView(
                title: "Graphics Score",
                value: result.graphicsScore,
                description: "Measures graphics performance using repeated rendering work. Higher scores usually mean smoother animation, stronger game performance and better handling of visually demanding apps.",
                deltaText: deltaText(current: result.graphicsScore, previous: comparisonBase?.graphicsScore)
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Report Card")
                    .font(.headline)

                HStack(spacing: 12) {
                    miniMetricBadge(title: "CPU", systemImage: "cpu", tint: .blue)
                    miniMetricBadge(title: "RAM", systemImage: "memorychip", tint: .purple)
                    miniMetricBadge(title: "SSD", systemImage: "internaldrive", tint: .orange)
                    miniMetricBadge(title: "GPU", systemImage: "display", tint: .pink)
                }

                HStack(alignment: .top, spacing: 14) {
                    reportPill(title: "Tier", value: result.performanceTier, color: tierColor)
                    reportPill(title: "Bottleneck", value: result.bottleneck, color: bottleneckColor)
                    Spacer(minLength: 0)
                }

                Text(result.reportSummary)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Notes & Tags")
                    .font(.headline)

                if result.note.isEmpty {
                    Text("No note added for this run.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Text(result.note)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                if result.tags.isEmpty {
                    Text("No tags")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(result.tags, id: \.self) { tag in
                                detailTagChip(tag)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)

            VStack(alignment: .leading, spacing: 12) {
                Text("Estimated Device Reference")
                    .font(.headline)

                Text(deviceReferenceSummary)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                ForEach(deviceReferenceRows, id: \.name) { row in
                    comparisonRow(name: row.name, score: row.score)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)

            // Insights and percentile
            VStack(alignment: .leading, spacing: 10) {
                Text("Insights")
                    .font(.headline)

                Text(generateInsight())
                    .font(.callout)
                    .foregroundColor(.secondary)

                Text(percentileText())
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.blue)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)
        }
        .padding(
            .horizontal,
            horizontalSizeClass == .compact ? 16.0 : 0.0
        )
        .padding(.vertical)
        .navigationTitle("Result")
        .toolbar {
            ToolbarItem(placement: .bencherTopBarTrailing) {
                ShareLink(item: shareSummaryText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
    
    private var shareSummaryText: String {
        """
        Bencher Result
        Device: \(result.deviceName)
        Overall Score: \(String(format: "%.0f", result.overallScore))
        Tier: \(result.performanceTier)
        Benchmark Type: \(result.benchmarkIntensity)
        Graphics Backend: \(result.graphicsBackend)
        Single-Core: \(String(format: "%.0f", result.singleCoreScore))
        Multi-Core: \(String(format: "%.0f", result.cpuScore))
        Memory: \(String(format: "%.0f", result.memoryScore))
        SSD: \(String(format: "%.0f", result.ssdScore))
        Graphics: \(String(format: "%.0f", result.graphicsScore))
        Thermal State: \(thermalStateText(result.thermalState))
        Power State: \(powerConnectionText(result.wasConnectedToPower))
        """
    }

    private var comparisonWarningText: String? {
        benchmarkComparisonWarning(primary: result, secondary: comparisonBase)
    }
    
    @ViewBuilder
    private func detailStatusChip(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func detailTagChip(_ tag: String) -> some View {
        Text(tag)
            .font(.caption.weight(.semibold))
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.08))
            .clipShape(Capsule())
    }

    private func benchmarkComparisonNotice(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private var tierColor: Color {
        switch result.performanceTier {
        case "Elite":
            return .green
        case "High-End":
            return .blue
        case "Upper Mid":
            return .yellow
        case "Mid":
            return .orange
        default:
            return .red
        }
    }

    private var bottleneckColor: Color {
        switch result.bottleneck {
        case "None":
            return .green
        case "CPU scaling":
            return .orange
        case "Storage":
            return .purple
        case "Memory":
            return .pink
        default:
            return .gray
        }
    }

    private var deviceReferenceSummary: String {
        "These are estimated broad ranges based on this app's calibrated scoring model and the detected device class. They are intended as practical guidance only and may vary depending on thermal conditions, storage state, battery level and OS behaviour."
    }

    private var deviceReferenceRows: [(name: String, score: String)] {
        switch result.deviceProfile {
        case .entry:
            return [
                ("Entry iPhone / older iPad", "~250 to 420 overall"),
                ("Strong result for this class", "~420+ overall")
            ]
        case .mid:
            return [
                ("Recent non-Pro iPhone / standard iPad", "~400 to 620 overall"),
                ("Strong result for this class", "~620+ overall")
            ]
        case .highEnd:
            return [
                ("Recent Pro iPhone / powerful iPad", "~550 to 760 overall"),
                ("Strong result for this class", "~760+ overall")
            ]
        case .elite:
            return [
                ("Pro Max / M-class iPad / Apple silicon Mac", "~700 to 950 overall"),
                ("Strong result for this class", "~950+ overall")
            ]
        }
    }
    
    @ViewBuilder
    private func miniMetricBadge(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func reportPill(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.78))

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minWidth: 112, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func thermalStateText(_ state: Int) -> String {
        switch state {
        case 0:
            return "Nominal"
        case 1:
            return "Fair"
        case 2:
            return "Serious"
        case 3:
            return "Critical"
        default:
            return "Unknown"
        }
    }

    private func powerConnectionText(_ state: Bool?) -> String {
        guard let state else { return "Unknown" }
        return state ? "On AC Power" : "Not on AC Power"
    }

    private func generateInsight() -> String {
        if result.ssdScore < 500 {
            return "Storage performance is lower than expected. Your device may have been warm, or other activity may have been using the drive."
        }
        if result.cpuScore < result.singleCoreScore * 2 {
            return "Multi-core scaling is lower than expected. Not all cores may be fully utilised."
        }
        return "Performance is within expected range for this class of device."
    }

    private func percentileText() -> String {
        if result.overallScore > 850 {
            return "Top ~10% performance"
        } else if result.overallScore > 700 {
            return "Above average performance"
        } else {
            return "Average performance range"
        }
    }

    private func deltaText(current: Double, previous: Double?) -> String? {
        guard let previous else { return nil }
        let delta = current - previous
        let sign = delta >= 0 ? "+" : ""
        return "Compared with previous run: \(sign)\(String(format: "%.0f", delta))"
    }

    @ViewBuilder
    private func comparisonRow(name: String, score: String) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(score)
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }
}

// MARK: - Result Metric View
struct ResultMetricView: View {
    let title: String
    let value: Double
    let description: Text
    let deltaText: String?

    init(title: String, value: Double, description: String, deltaText: String?) {
        self.title = title
        self.value = value
        self.description = Text(description)
        self.deltaText = deltaText
    }

    init(title: String, value: Double, description: Text, deltaText: String?) {
        self.title = title
        self.value = value
        self.description = description
        self.deltaText = deltaText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            Text(String(format: "%.0f", value))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            if let deltaText {
                Text(deltaText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(deltaText.contains("+") ? .green : .orange)
            }

            description
                .font(.callout)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
    }
}

// MARK: - Benchmark Result Model
struct BenchmarkResult: Identifiable, Equatable, Codable {
    let id: UUID
    let sessionID: UUID
    let deviceName: String
    let benchmarkIntensity: String
    let note: String
    let tags: [String]
    let isPinned: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case sessionID
        case deviceName
        case benchmarkIntensity
        case note
        case tags
        case isPinned
        case singleCoreScore
        case cpuScore
        case memoryScore
        case memoryRawThroughputMBps
        case ssdScore
        case ssdRawCombinedMBps
        case ssdRawReadMBps
        case ssdRawWriteMBps
        case graphicsBackend
        case graphicsScore
        case rawSingleCoreScore
        case rawMultiCoreScore
        case rawMemoryScore
        case rawSSDScore
        case rawGraphicsScore
        case overallScore
        case timestamp
        case thermalState
        case wasConnectedToPower
        case reliability
        case validationMessages
    }

    let thermalState: Int
    let wasConnectedToPower: Bool?
    
    func normalizedDeviceNameIfNeeded() -> BenchmarkResult {
        let normalizedName = DeviceModel.normalizedDisplayName(deviceName: deviceName)
        guard normalizedName != deviceName else { return self }

        return BenchmarkResult(
            id: id,
            sessionID: sessionID,
            deviceName: normalizedName,
            benchmarkIntensity: benchmarkIntensity,
            note: note,
            tags: tags,
            isPinned: isPinned,
            singleCoreScore: singleCoreScore,
            cpuScore: cpuScore,
            memoryScore: memoryScore,
            memoryRawThroughputMBps: memoryRawThroughputMBps,
            ssdScore: ssdScore,
            ssdRawCombinedMBps: ssdRawCombinedMBps,
            ssdRawReadMBps: ssdRawReadMBps,
            ssdRawWriteMBps: ssdRawWriteMBps,
            graphicsBackend: graphicsBackend,
            graphicsScore: graphicsScore,
            rawSingleCoreScore: rawSingleCoreScore,
            rawMultiCoreScore: rawMultiCoreScore,
            rawMemoryScore: rawMemoryScore,
            rawSSDScore: rawSSDScore,
            rawGraphicsScore: rawGraphicsScore,
            overallScore: overallScore,
            timestamp: timestamp,
            thermalState: thermalState,
            wasConnectedToPower: wasConnectedToPower,
            reliability: reliability,
            validationMessages: validationMessages
        )
    }

    init(
        id: UUID = UUID(),
        sessionID: UUID = UUID(),
        deviceName: String,
        benchmarkIntensity: String,
        note: String = "",
        tags: [String] = [],
        isPinned: Bool = false,
        singleCoreScore: Double,
        cpuScore: Double,
        memoryScore: Double,
        memoryRawThroughputMBps: Double,
        ssdScore: Double,
        ssdRawCombinedMBps: Double,
        ssdRawReadMBps: Double,
        ssdRawWriteMBps: Double,
        graphicsBackend: String = GraphicsBenchmarkBackend.legacy.rawValue,
        graphicsScore: Double,
        rawSingleCoreScore: Double? = nil,
        rawMultiCoreScore: Double? = nil,
        rawMemoryScore: Double? = nil,
        rawSSDScore: Double? = nil,
        rawGraphicsScore: Double? = nil,
        overallScore: Double,
        timestamp: Date,
        thermalState: Int,
        wasConnectedToPower: Bool? = nil,
        reliability: BenchmarkReliability = .good,
        validationMessages: [String] = []
    ) {
        self.id = id
        self.sessionID = sessionID
        self.deviceName = deviceName
        self.benchmarkIntensity = benchmarkIntensity
        self.note = note
        self.tags = tags
        self.isPinned = isPinned
        self.singleCoreScore = singleCoreScore
        self.cpuScore = cpuScore
        self.memoryScore = memoryScore
        self.memoryRawThroughputMBps = memoryRawThroughputMBps
        self.ssdScore = ssdScore
        self.ssdRawCombinedMBps = ssdRawCombinedMBps
        self.ssdRawReadMBps = ssdRawReadMBps
        self.ssdRawWriteMBps = ssdRawWriteMBps
        self.graphicsBackend = graphicsBackend
        self.graphicsScore = graphicsScore
        self.rawSingleCoreScore = rawSingleCoreScore ?? singleCoreScore
        self.rawMultiCoreScore = rawMultiCoreScore ?? cpuScore
        self.rawMemoryScore = rawMemoryScore ?? memoryScore
        self.rawSSDScore = rawSSDScore ?? ssdScore
        self.rawGraphicsScore = rawGraphicsScore ?? graphicsScore
        self.overallScore = overallScore
        self.timestamp = timestamp
        self.thermalState = thermalState
        self.wasConnectedToPower = wasConnectedToPower
        self.reliability = reliability
        self.validationMessages = validationMessages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        sessionID = try container.decodeIfPresent(UUID.self, forKey: .sessionID) ?? UUID()
        deviceName = try container.decodeIfPresent(String.self, forKey: .deviceName) ?? DeviceModel.currentDeviceName()
        benchmarkIntensity = try container.decodeIfPresent(String.self, forKey: .benchmarkIntensity) ?? "Balanced"
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        singleCoreScore = try container.decodeIfPresent(Double.self, forKey: .singleCoreScore) ?? 0
        cpuScore = try container.decodeIfPresent(Double.self, forKey: .cpuScore) ?? 0
        memoryScore = try container.decodeIfPresent(Double.self, forKey: .memoryScore) ?? 0
        memoryRawThroughputMBps = try container.decodeIfPresent(Double.self, forKey: .memoryRawThroughputMBps) ?? memoryScore
        ssdScore = try container.decodeIfPresent(Double.self, forKey: .ssdScore) ?? 0
        ssdRawCombinedMBps = try container.decodeIfPresent(Double.self, forKey: .ssdRawCombinedMBps) ?? ssdScore
        ssdRawReadMBps = try container.decodeIfPresent(Double.self, forKey: .ssdRawReadMBps) ?? ssdRawCombinedMBps
        ssdRawWriteMBps = try container.decodeIfPresent(Double.self, forKey: .ssdRawWriteMBps) ?? ssdRawCombinedMBps
        graphicsBackend = try container.decodeIfPresent(String.self, forKey: .graphicsBackend) ?? GraphicsBenchmarkBackend.legacy.rawValue
        graphicsScore = try container.decodeIfPresent(Double.self, forKey: .graphicsScore) ?? 0
        rawSingleCoreScore = try container.decodeIfPresent(Double.self, forKey: .rawSingleCoreScore) ?? singleCoreScore
        rawMultiCoreScore = try container.decodeIfPresent(Double.self, forKey: .rawMultiCoreScore) ?? cpuScore
        rawMemoryScore = try container.decodeIfPresent(Double.self, forKey: .rawMemoryScore) ?? memoryScore
        rawSSDScore = try container.decodeIfPresent(Double.self, forKey: .rawSSDScore) ?? ssdScore
        rawGraphicsScore = try container.decodeIfPresent(Double.self, forKey: .rawGraphicsScore) ?? graphicsScore
        overallScore = try container.decodeIfPresent(Double.self, forKey: .overallScore) ?? 0
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        thermalState = try container.decodeIfPresent(Int.self, forKey: .thermalState) ?? 0
        wasConnectedToPower = try container.decodeIfPresent(Bool.self, forKey: .wasConnectedToPower)
        reliability = try container.decodeIfPresent(BenchmarkReliability.self, forKey: .reliability) ?? .good
        validationMessages = try container.decodeIfPresent([String].self, forKey: .validationMessages) ?? []
    }

    let singleCoreScore: Double
    let cpuScore: Double
    let memoryScore: Double
    let memoryRawThroughputMBps: Double
    let ssdScore: Double
    let ssdRawCombinedMBps: Double
    let ssdRawReadMBps: Double
    let ssdRawWriteMBps: Double
    let graphicsBackend: String
    let graphicsScore: Double
    let rawSingleCoreScore: Double
    let rawMultiCoreScore: Double
    let rawMemoryScore: Double
    let rawSSDScore: Double
    let rawGraphicsScore: Double
    let overallScore: Double
    let timestamp: Date
    let reliability: BenchmarkReliability
    let validationMessages: [String]
}

extension BenchmarkResult {
    var hasValidationWarnings: Bool {
        !validationMessages.isEmpty
    }

    var performanceTier: String {
        switch overallScore {
        case 850...:
            return "Elite"
        case 700..<850:
            return "High-End"
        case 550..<700:
            return "Upper Mid"
        case 400..<550:
            return "Mid"
        default:
            return "Entry"
        }
    }

    var bottleneck: String {
        if cpuScore < singleCoreScore * 2 {
            return "CPU scaling"
        }
        if ssdScore < 500 {
            return "Storage"
        }
        if memoryScore < 300 {
            return "Memory"
        }
        return "None"
    }

    var reportSummary: String {
        if bottleneck == "None" {
            return "This run looks well balanced overall, with no obvious weak link standing out relative to the rest of the benchmark profile."
        }
        return "The main area worth watching in this run is \(bottleneck.lowercased()). This does not necessarily indicate a fault, but it is the part of the profile most likely to be limiting the overall result."
    }

    var deviceProfile: DevicePerformanceProfile {
        let name = deviceName.lowercased()

        if name.contains("pro max")
            || name.contains("m1")
            || name.contains("m2")
            || name.contains("m3")
            || name.contains("m4")
            || name.contains("macbook pro")
            || name.contains("mac studio")
            || name.contains("mac mini")
            || name.contains("imac") {
            return .elite
        }

        if name.contains("pro") || name.contains("ipad pro") {
            return .highEnd
        }

        if name.contains("ipad") || name.contains("plus") || name.contains("air") {
            return .mid
        }

        return .entry
    }
}

enum DevicePerformanceProfile {
    case entry
    case mid
    case highEnd
    case elite
}

// MARK: - Progress Bar
struct ProgressBar: View {
    @Binding var progress: Double
    var color: Color

    var body: some View {
        GeometryReader { geometry in
            let clampedProgress = min(max(progress, 0.0), 1.0)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemFill))
                    .frame(height: 20)

                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .frame(width: geometry.size.width * clampedProgress, height: 20)
            }
        }
        .frame(height: 20)
        .animation(.easeInOut(duration: 0.2), value: progress)
    }
}

// MARK: - Score Card
struct ScoreCard: View {
    let title: String
    let score: Double
    let color: Color
    var isBold: Bool = false
    var footerText: String? = nil
    @State private var hasAnimatedIn: Bool = false

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(String(format: "%.0f", score))
                .font(isBold ? .largeTitle : .title)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundColor(color)

            if let footerText {
                Text(footerText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(BencherPlatformColors.secondaryBackground)
        )
        .padding(.horizontal)
        .scaleEffect(hasAnimatedIn ? 1.0 : 0.97)
        .opacity(hasAnimatedIn ? 1.0 : 0.0)
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: hasAnimatedIn)
        .onAppear {
            hasAnimatedIn = true
        }
    }
}

// MARK: - Benchmark Functions
private enum BenchmarkBlackHole {
    private static var sink: Double = 0

    @inline(never)
    static func consume(_ value: Double) {
        sink += value.isFinite ? value : 0.000_001
    }
}

enum GraphicsBenchmarkBackend: String, Identifiable, Codable {
    case metal = "Metal"
    case openCL = "OpenCL"
    case legacy = "Legacy Renderer"

    var id: String { rawValue }

    static var settingsOptions: [GraphicsBenchmarkBackend] {
        #if os(macOS)
        [.metal, .openCL]
        #else
        [.metal, .legacy]
        #endif
    }

    static var settingsHelpText: String {
        #if os(macOS)
        "Metal is the recommended option. OpenCL is available as a Mac-only fallback, and only Metal graphics runs are shown in Trends."
        #else
        "Metal is the recommended option. Legacy Renderer is available for comparison, but only Metal graphics runs are shown in Trends."
        #endif
    }
}

private let preferredReferenceBenchmarkIntensity = "Balanced"

private func usesPreferredComparisonParameters(_ result: BenchmarkResult) -> Bool {
    result.benchmarkIntensity == preferredReferenceBenchmarkIntensity
    && result.graphicsBackend == GraphicsBenchmarkBackend.metal.rawValue
}

func comparableBenchmarkBaseline(for result: BenchmarkResult, within scores: [BenchmarkResult]) -> BenchmarkResult? {
    scores
        .filter {
            $0.id != result.id
            && $0.timestamp < result.timestamp
            && $0.deviceName == result.deviceName
            && $0.benchmarkIntensity == result.benchmarkIntensity
            && $0.graphicsBackend == result.graphicsBackend
        }
        .sorted(by: { $0.timestamp > $1.timestamp })
        .first
}

private func benchmarkComparisonWarning(primary: BenchmarkResult, secondary: BenchmarkResult? = nil) -> String? {
    if let secondary {
        let hasDifferentSetup = primary.benchmarkIntensity != secondary.benchmarkIntensity
            || primary.graphicsBackend != secondary.graphicsBackend

        if hasDifferentSetup {
            return "These two runs were recorded with different benchmark settings, so this is better treated as a rough comparison than a like-for-like one."
        }
        let usesPreferredSetup = usesPreferredComparisonParameters(primary)
            && usesPreferredComparisonParameters(secondary)
        guard !usesPreferredSetup else { return nil }
        return "One of these runs used a less typical setup, so this side-by-side view is best treated as a rough guide. For the fairest match, compare Balanced runs using Metal."
    }

    guard primary.graphicsBackend == GraphicsBenchmarkBackend.legacy.rawValue else { return nil }
    return "This run used Bencher's older graphics method, so its graphics score may not line up perfectly with newer results."
}

private func benchmarkBackendFilterTitle(_ backend: String) -> String {
    backend == "All Graphics Paths" ? backend : backend
}

class Benchmark {
    private let cpuTaskIterations: Int
        private let largeArraySize: Int
        private let memoryBaseline: UInt64 = 1_000 * 1024 * 1024
        private let normalizationFactor: Double = 10_000.0
        private let ssdFileSize: Int
        private let ssdChunkSize: Int
        private let graphicsFrameCount: Int
        private let preferredGraphicsBackend: GraphicsBenchmarkBackend
        private(set) var lastGraphicsBackendUsed: GraphicsBenchmarkBackend

        init(intensity: String = "Balanced", graphicsBackend: String = GraphicsBenchmarkBackend.metal.rawValue) {
            let requestedBackend = GraphicsBenchmarkBackend(rawValue: graphicsBackend) ?? .metal
            #if os(macOS)
            preferredGraphicsBackend = requestedBackend == .legacy ? .openCL : requestedBackend
            #else
            preferredGraphicsBackend = requestedBackend == .openCL ? .legacy : requestedBackend
            #endif
            lastGraphicsBackendUsed = preferredGraphicsBackend
            switch intensity {
            case "Light":
                cpuTaskIterations = 220_000_000
                largeArraySize = 40_000_000
                ssdFileSize = 64 * 1024 * 1024
                ssdChunkSize = 4 * 1024 * 1024
                graphicsFrameCount = 1_800
            case "Extreme":
                cpuTaskIterations = 800_000_000
                largeArraySize = 160_000_000
                ssdFileSize = 256 * 1024 * 1024
                ssdChunkSize = 8 * 1024 * 1024
                graphicsFrameCount = 4_500
            default:
                cpuTaskIterations = 500_000_000
                largeArraySize = 100_000_000
                ssdFileSize = 128 * 1024 * 1024
                ssdChunkSize = 8 * 1024 * 1024
                graphicsFrameCount = 3_000
            }
        }

    @_optimize(none)
    func measureCPUBenchmark() -> Double {
        let coreCount = max(ProcessInfo.processInfo.activeProcessorCount, 2)
        let iterationsPerCore = max(cpuTaskIterations / coreCount, 25_000_000)
        let totals = UnsafeMutableBufferPointer<Double>.allocate(capacity: coreCount)
        defer { totals.deallocate() }

        for index in 0..<coreCount {
            totals[index] = 0
        }

        let start = CFAbsoluteTimeGetCurrent()

        DispatchQueue.concurrentPerform(iterations: coreCount) { coreIndex in
            let startIndex = coreIndex * iterationsPerCore + 1
            let endIndex = startIndex + iterationsPerCore
            totals[coreIndex] = cpuKernelSlice(startIndex: startIndex, endIndex: endIndex)
        }

        BenchmarkBlackHole.consume(totals.reduce(0, +))

        let timeTaken = CFAbsoluteTimeGetCurrent() - start
        guard timeTaken > 0 else { return 0 }

        let effectiveIterations = Double(iterationsPerCore * coreCount)
        let scalingFactor = max(pow(Double(coreCount), 0.25), 1.0)
        let rawScore = (effectiveIterations / timeTaken) / scalingFactor
        return rawScore / normalizationFactor
    }

    @_optimize(none)
    func measureMemoryBenchmark() -> (score: Double, throughputMBps: Double) {
        let elementCount = min(largeArraySize / 8, 12_000_000)
        var buffer = Array(repeating: Double.zero, count: elementCount)
        let passes = 4

        let start = CFAbsoluteTimeGetCurrent()

        for pass in 0..<passes {
            let passValue = Double(pass + 1)
            for index in buffer.indices {
                let value = Double(index)
                buffer[index] = (value * 0.000001 + passValue).squareRoot()
            }

            for index in stride(from: 1, to: buffer.count, by: 2) {
                buffer[index] += buffer[index - 1] * 0.0001
            }
        }

        let checksum = stride(from: 0, to: buffer.count, by: 97).reduce(0.0) { partial, index in
            partial + buffer[index]
        }
        BenchmarkBlackHole.consume(checksum)

        let timeTaken = CFAbsoluteTimeGetCurrent() - start
        guard timeTaken > 0 else { return (0, 0) }

        let bytesProcessed = Double(elementCount * MemoryLayout<Double>.size * passes * 2)
        let throughputMBps = bytesProcessed / timeTaken / 1_000_000
        let memoryUsagePenalty = max(Double(reportMemory()) / Double(memoryBaseline), 1.0)
        let rawScore = throughputMBps / memoryUsagePenalty
        return (rawScore, throughputMBps)
    }

    @_optimize(none)
    func measureSSDSpeed() -> (score: Double, combinedMBps: Double, readMBps: Double, writeMBps: Double) {
        let fileSize = ssdFileSize
        let chunkSize = ssdChunkSize
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("benchmark.tmp")

        defer { try? FileManager.default.removeItem(at: tempURL) }

        _ = FileManager.default.createFile(atPath: tempURL.path, contents: nil)
        let pattern = Data((0..<chunkSize).map { UInt8($0 % 251) })

        do {
            let writer = try FileHandle(forWritingTo: tempURL)
            defer { try? writer.close() }
            _ = fcntl(writer.fileDescriptor, F_NOCACHE, 1)

            var remainingWrite = fileSize
            let startWrite = CFAbsoluteTimeGetCurrent()
            while remainingWrite > 0 {
                let currentSize = min(chunkSize, remainingWrite)
                if currentSize == chunkSize {
                    try writer.write(contentsOf: pattern)
                } else {
                    try writer.write(contentsOf: pattern.prefix(currentSize))
                }
                remainingWrite -= currentSize
            }
            try writer.synchronize()
            _ = fsync(writer.fileDescriptor)
            let writeTime = CFAbsoluteTimeGetCurrent() - startWrite

            let reader = try FileHandle(forReadingFrom: tempURL)
            defer { try? reader.close() }
            _ = fcntl(reader.fileDescriptor, F_NOCACHE, 1)

            var checksum: UInt64 = 0
            let startRead = CFAbsoluteTimeGetCurrent()
            while true {
                let chunk = try reader.read(upToCount: chunkSize) ?? Data()
                if chunk.isEmpty { break }

                chunk.withUnsafeBytes { rawBuffer in
                    guard let bytes = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return }
                    let strideSize = 64
                    var index = 0
                    while index < chunk.count {
                        checksum &+= UInt64(bytes[index])
                        index += strideSize
                    }
                }
            }
            let readTime = CFAbsoluteTimeGetCurrent() - startRead

            _ = checksum

            guard writeTime > 0, readTime > 0 else { return (0, 0, 0, 0) }

            let readMBps = Double(fileSize) / readTime / 1_000_000
            let writeMBps = Double(fileSize) / writeTime / 1_000_000
            let combinedMBps = (readMBps + writeMBps) / 2.0
            return (combinedMBps, combinedMBps, readMBps, writeMBps)
        } catch {
            return (0, 0, 0, 0)
        }
    }

    @_optimize(none)
    func measureGraphicsRendering() -> Double {
        if preferredGraphicsBackend == .metal {
            #if canImport(Metal)
            if let metalScore = measureMetalGraphicsRendering() {
                lastGraphicsBackendUsed = .metal
                return metalScore
            }
            #endif
            lastGraphicsBackendUsed = .metal
            return 0
        } else if preferredGraphicsBackend == .openCL {
            #if os(macOS)
            if let openCLScore = measureOpenCLGraphicsRendering() {
                lastGraphicsBackendUsed = .openCL
                return openCLScore
            }
            #endif
            lastGraphicsBackendUsed = .openCL
            return 0
        }

        lastGraphicsBackendUsed = .legacy

        let frameCount = graphicsFrameCount
        let start = CFAbsoluteTimeGetCurrent()
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        for frame in 0..<frameCount {
            _ = renderer.image { context in
                let cgContext = context.cgContext
                drawGraphicsBenchmarkFrame(in: cgContext, frame: frame)
            }
        }
        #elseif canImport(AppKit)
        let imageSize = NSSize(width: 256, height: 256)
        for frame in 0..<frameCount {
            renderAppKitGraphicsFrame(size: imageSize, frame: frame)
        }
        #endif
        let timeTaken = CFAbsoluteTimeGetCurrent() - start
        guard timeTaken > 0 else { return 0 }

        let framesPerSecondEquivalent = Double(frameCount) / timeTaken
        return framesPerSecondEquivalent * 5.0
    }

    #if canImport(Metal)
    @_optimize(none)
    private func measureMetalGraphicsRendering() -> Double? {
        for workload in metalWorkloads {
            var samples: [Double] = []

            for _ in 0..<3 {
                if let score = runMetalGraphicsWorkload(
                    elementCount: workload.elementCount,
                    kernelIterations: workload.kernelIterations,
                    passCount: workload.passCount
                ), score.isFinite, score > 0 {
                    samples.append(score)
                }
            }

            if let median = medianBenchmarkSample(samples) {
                return median
            }
        }

        return nil
    }

    private var metalWorkloads: [(elementCount: Int, kernelIterations: UInt32, passCount: Int)] {
        [
            (elementCount: 1_048_576, kernelIterations: 224, passCount: 18),
            (elementCount: 786_432, kernelIterations: 192, passCount: 18),
            (elementCount: 524_288, kernelIterations: 160, passCount: 16)
        ]
    }

    private func preferredMetalDevice() -> MTLDevice? {
        #if os(macOS)
        let devices = MTLCopyAllDevices()
        return devices.first(where: { !$0.isRemovable }) ?? devices.first ?? MTLCreateSystemDefaultDevice()
        #else
        MTLCreateSystemDefaultDevice()
        #endif
    }

    @_optimize(none)
    private func runMetalGraphicsWorkload(elementCount: Int, kernelIterations: UInt32, passCount: Int) -> Double? {
        guard let device = preferredMetalDevice(),
              let commandQueue = device.makeCommandQueue(),
              let pipelineState = makeMetalGraphicsPipeline(device: device) else {
            return nil
        }

        commandQueue.label = "BencherGraphicsQueue"

        let vectorStride = MemoryLayout<SIMD4<Float>>.stride
        let bufferLength = elementCount * vectorStride
        guard let outputBuffer = device.makeBuffer(length: bufferLength, options: .storageModeShared) else {
            return nil
        }

        outputBuffer.label = "BencherGraphicsOutput"

        let executionWidth = max(pipelineState.threadExecutionWidth, 1)
        let maxThreads = max(pipelineState.maxTotalThreadsPerThreadgroup, executionWidth)
        let threadgroupWidth = min(maxThreads, executionWidth * 8)
        let threadsPerThreadgroup = MTLSize(width: threadgroupWidth, height: 1, depth: 1)
        let threadsPerGrid = MTLSize(width: elementCount, height: 1, depth: 1)

        guard warmMetalComputePipeline(
            commandQueue: commandQueue,
            pipelineState: pipelineState,
            outputBuffer: outputBuffer,
            threadsPerGrid: threadsPerGrid,
            threadsPerThreadgroup: threadsPerThreadgroup,
            kernelIterations: 16,
            seed: 0
        ) else {
            return nil
        }

        let start = CFAbsoluteTimeGetCurrent()

        for pass in 0..<passCount {
            autoreleasepool {
                guard let commandBuffer = commandQueue.makeCommandBuffer(),
                      let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                    return
                }

                var passSeed = UInt32(pass)
                var iterationCount = kernelIterations
                computeEncoder.setComputePipelineState(pipelineState)
                computeEncoder.setBuffer(outputBuffer, offset: 0, index: 0)
                computeEncoder.setBytes(&iterationCount, length: MemoryLayout<UInt32>.stride, index: 1)
                computeEncoder.setBytes(&passSeed, length: MemoryLayout<UInt32>.stride, index: 2)
                computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
                computeEncoder.endEncoding()
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()

                if commandBuffer.status != .completed || commandBuffer.error != nil {
                    return
                }
            }
        }

        let timeTaken = CFAbsoluteTimeGetCurrent() - start
        guard timeTaken > 0 else { return nil }

        let values = outputBuffer.contents().bindMemory(to: SIMD4<Float>.self, capacity: elementCount)
        var checksum = 0.0
        let sampleStride = max(elementCount / 1024, 1)
        for index in stride(from: 0, to: elementCount, by: sampleStride) {
            let value = values[index]
            checksum += Double(value.x + value.y + value.z + value.w)
        }
        guard checksum.isFinite, checksum != 0 else { return nil }
        BenchmarkBlackHole.consume(checksum)

        let totalOperations = Double(elementCount) * Double(kernelIterations) * Double(passCount)
        return totalOperations / timeTaken / 1_000_000
    }

    private func medianBenchmarkSample(_ samples: [Double]) -> Double? {
        let usableSamples = samples.filter { $0.isFinite && $0 > 0 }.sorted()
        guard !usableSamples.isEmpty else { return nil }
        let middleIndex = usableSamples.count / 2
        if usableSamples.count.isMultiple(of: 2) {
            return (usableSamples[middleIndex - 1] + usableSamples[middleIndex]) / 2
        }
        return usableSamples[middleIndex]
    }

    private func makeMetalGraphicsPipeline(device: MTLDevice) -> MTLComputePipelineState? {
        do {
            let library = try device.makeDefaultLibrary(bundle: .main)
            guard let function = library.makeFunction(name: "bencherGraphics") else {
                return nil
            }
            return try device.makeComputePipelineState(function: function)
        } catch {
            return nil
        }
    }

    private func warmMetalComputePipeline(
        commandQueue: MTLCommandQueue,
        pipelineState: MTLComputePipelineState,
        outputBuffer: MTLBuffer,
        threadsPerGrid: MTLSize,
        threadsPerThreadgroup: MTLSize,
        kernelIterations: UInt32,
        seed: UInt32
    ) -> Bool {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return false
        }

        var warmIterations = kernelIterations
        var warmSeed = seed
        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setBuffer(outputBuffer, offset: 0, index: 0)
        computeEncoder.setBytes(&warmIterations, length: MemoryLayout<UInt32>.stride, index: 1)
        computeEncoder.setBytes(&warmSeed, length: MemoryLayout<UInt32>.stride, index: 2)
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        return commandBuffer.status == .completed
    }
    #endif

    #if os(macOS)
    @_optimize(none)
    private func measureOpenCLGraphicsRendering() -> Double? {
        var platformCount: cl_uint = 0
        guard clGetPlatformIDs(0, nil, &platformCount) == CL_SUCCESS, platformCount > 0 else {
            return nil
        }

        let platformCapacity = Int(platformCount)
        let platforms = UnsafeMutablePointer<cl_platform_id?>.allocate(capacity: platformCapacity)
        defer { platforms.deallocate() }

        guard clGetPlatformIDs(platformCount, platforms, nil) == CL_SUCCESS else {
            return nil
        }

        for index in 0..<platformCapacity {
            guard let platform = platforms[index] else { continue }
            if let score = runOpenCLGraphicsWorkload(on: platform) {
                return score
            }
        }

        return nil
    }

    private func runOpenCLGraphicsWorkload(on platform: cl_platform_id) -> Double? {
        let deviceTypes: [cl_device_type] = [cl_device_type(CL_DEVICE_TYPE_GPU), cl_device_type(CL_DEVICE_TYPE_DEFAULT)]

        for deviceType in deviceTypes {
            var deviceCount: cl_uint = 0
            let countStatus = clGetDeviceIDs(platform, deviceType, 0, nil, &deviceCount)
            guard countStatus == CL_SUCCESS, deviceCount > 0 else { continue }

            let devices = UnsafeMutablePointer<cl_device_id?>.allocate(capacity: Int(deviceCount))
            defer { devices.deallocate() }

            guard clGetDeviceIDs(platform, deviceType, deviceCount, devices, nil) == CL_SUCCESS,
                  let device = devices[0] else {
                continue
            }

            if let score = executeOpenCLGraphicsWorkload(device: device) {
                return score
            }
        }

        return nil
    }

    @_optimize(none)
    private func executeOpenCLGraphicsWorkload(device: cl_device_id) -> Double? {
        var deviceRef: cl_device_id? = device
        var contextError: cl_int = 0
        guard let context = clCreateContext(nil, 1, &deviceRef, nil, nil, &contextError),
              contextError == CL_SUCCESS else {
            return nil
        }
        defer { clReleaseContext(context) }

        var queueError: cl_int = 0
        guard let commandQueue = clCreateCommandQueue(context, device, 0, &queueError),
              queueError == CL_SUCCESS else {
            return nil
        }
        defer { clReleaseCommandQueue(commandQueue) }

        let elementCount = max(graphicsFrameCount * 1024, 512 * 1024)
        let bufferLength = elementCount * MemoryLayout<Float>.stride

        var bufferError: cl_int = 0
        guard let outputBuffer = clCreateBuffer(context, cl_mem_flags(CL_MEM_READ_WRITE), bufferLength, nil, &bufferError),
              bufferError == CL_SUCCESS else {
            return nil
        }
        defer { clReleaseMemObject(outputBuffer) }

        let source = """
        __kernel void bencherGraphics(__global float *output, float timeSeed) {
            int gid = get_global_id(0);
            float x = (float)gid * 0.00021f + timeSeed;
            float y = native_sin(x) * native_cos(x * 0.51f);
            float z = native_sqrt(fabs(y) + 1.0f) + native_log(x + 1.5f);
            output[gid] = y + z;
        }
        """

        let program: cl_program? = source.utf8CString.withUnsafeBufferPointer { buffer in
            var sourcePointer = buffer.baseAddress
            var sourceLength = buffer.count - 1
            var programError: cl_int = 0
            let createdProgram = clCreateProgramWithSource(context, 1, &sourcePointer, &sourceLength, &programError)
            return programError == CL_SUCCESS ? createdProgram : nil
        }
        guard let program else { return nil }
        defer { clReleaseProgram(program) }

        guard clBuildProgram(program, 1, &deviceRef, nil, nil, nil) == CL_SUCCESS else {
            return nil
        }

        var kernelError: cl_int = 0
        guard let kernel = clCreateKernel(program, "bencherGraphics", &kernelError),
              kernelError == CL_SUCCESS else {
            return nil
        }
        defer { clReleaseKernel(kernel) }

        var outputBufferRef: cl_mem? = outputBuffer
        guard clSetKernelArg(kernel, 0, MemoryLayout<cl_mem?>.stride, &outputBufferRef) == CL_SUCCESS else {
            return nil
        }

        let workItems = max(elementCount, 64 * 1024)
        let globalWorkSize = [workItems]
        let localWorkSize = [min(256, workItems)]
        let passes = max(graphicsFrameCount / 30, 60)

        let start = CFAbsoluteTimeGetCurrent()

        for pass in 0..<passes {
            var timeSeed = Float(pass) * 0.03125
            guard clSetKernelArg(kernel, 1, MemoryLayout<Float>.stride, &timeSeed) == CL_SUCCESS else {
                return nil
            }

            let enqueueStatus = clEnqueueNDRangeKernel(
                commandQueue,
                kernel,
                1,
                nil,
                globalWorkSize,
                localWorkSize,
                0,
                nil,
                nil
            )

            guard enqueueStatus == CL_SUCCESS else {
                return nil
            }
        }

        guard clFinish(commandQueue) == CL_SUCCESS else {
            return nil
        }

        let timeTaken = CFAbsoluteTimeGetCurrent() - start
        guard timeTaken > 0 else { return nil }

        let operations = Double(workItems * passes)
        return operations / timeTaken / 100_000
    }
    #endif

    #if canImport(UIKit)
    @_optimize(none)
    private func drawGraphicsBenchmarkFrame(in cgContext: CGContext, frame: Int) {
        let inset = CGFloat((frame % 20) + 1)

        UIColor.systemBlue.setFill()
        cgContext.fill(CGRect(x: 0, y: 0, width: 256, height: 256))

        UIColor.systemPink.setStroke()
        cgContext.setLineWidth(3)
        cgContext.strokeEllipse(in: CGRect(x: inset, y: inset, width: 256 - (inset * 2), height: 256 - (inset * 2)))

        UIColor.white.setFill()
        cgContext.fill(CGRect(x: 40, y: 40, width: 176, height: 24))
        cgContext.fill(CGRect(x: 40, y: 90, width: 120, height: 24))
        cgContext.fill(CGRect(x: 40, y: 140, width: 200, height: 24))
    }
    #endif

    @_optimize(none)
    private func cpuKernelSlice(startIndex: Int, endIndex: Int) -> Double {
        var localSum = 0.0

        for i in startIndex..<endIndex {
            let value = Double(i)
            localSum += sin(value) * cos(value * 0.5)
                + sin(value * 0.125) * 0.5
                + sqrt(value)
        }

        return localSum
    }

    #if canImport(AppKit)
    @_optimize(none)
    private func renderAppKitGraphicsFrame(size: NSSize, frame: Int) {
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)
        NSColor.systemBlue.setFill()
        rect.fill()

        let inset = CGFloat((frame % 20) + 1)
        let ellipseRect = NSRect(x: inset, y: inset, width: size.width - (inset * 2), height: size.height - (inset * 2))
        let ellipse = NSBezierPath(ovalIn: ellipseRect)
        ellipse.lineWidth = 3
        NSColor.systemPink.setStroke()
        ellipse.stroke()

        NSColor.white.setFill()
        NSRect(x: 40, y: 40, width: 176, height: 24).fill()
        NSRect(x: 40, y: 90, width: 120, height: 24).fill()
        NSRect(x: 40, y: 140, width: 200, height: 24).fill()

        image.unlockFocus()
    }
    #endif

    @_optimize(none)
    func measureSingleCoreBenchmark() -> Double {
        let singleCoreIterations = max(cpuTaskIterations / 6, 60_000_000)
        let start = CFAbsoluteTimeGetCurrent()
        var sum = 0.0

        for i in 1...singleCoreIterations {
            let value = Double(i)
            sum += sin(value) * cos(value * 0.5)
                + sin(value * 0.125) * 0.5
                + log(value + 1.0)
                + sqrt(value) * 0.001
        }

        BenchmarkBlackHole.consume(sum)

        let timeTaken = CFAbsoluteTimeGetCurrent() - start
        guard timeTaken > 0 else { return 0 }

        let rawScore = Double(singleCoreIterations) / timeTaken
        return rawScore / normalizationFactor
    }

    private func reportMemory() -> UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            return taskInfo.resident_size
        } else {
            return 0
        }
    }
}

// MARK: - Benchmark Storage
enum BenchmarkStorage {
    private static let localStorageKey = "bencher.history.v1"
    private static let iCloudStorageKey = "bencher.history.icloud.v1"
    private static let iCloudSyncEnabledKey = "icloudHistorySyncEnabled"

    private enum Backend {
        case local
        case iCloud
    }

    static func load() -> [BenchmarkResult] {
        load(from: activeBackend)
    }

    static func save(_ scores: [BenchmarkResult]) {
        save(scores, to: activeBackend)
    }

    static func prepareForLaunch() {
        guard isICloudSyncEnabled else { return }
        _ = NSUbiquitousKeyValueStore.default.synchronize()
    }

    static func setICloudSyncEnabled(_ isEnabled: Bool, currentScores: [BenchmarkResult]) -> [BenchmarkResult] {
        let normalizedCurrent = deduplicate(currentScores)
        UserDefaults.standard.set(isEnabled, forKey: iCloudSyncEnabledKey)

        if isEnabled {
            _ = NSUbiquitousKeyValueStore.default.synchronize()
            let merged = mergeForImport(existing: load(from: .iCloud), imported: normalizedCurrent)
            save(merged, to: .iCloud)
            return merged
        } else {
            let merged = mergeForImport(existing: load(from: .local), imported: normalizedCurrent)
            save(merged, to: .local)
            return merged
        }
    }

    static func mergeForImport(existing: [BenchmarkResult], imported: [BenchmarkResult]) -> [BenchmarkResult] {
        deduplicate(existing + imported)
    }

    private static var isICloudSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: iCloudSyncEnabledKey)
    }

    private static var activeBackend: Backend {
        isICloudSyncEnabled ? .iCloud : .local
    }

    private static func load(from backend: Backend) -> [BenchmarkResult] {
        guard let data = loadData(from: backend) else {
            return []
        }

        let decodedPayload = BencherCrypto.decryptStoragePayload(data) ?? data

        if let decoded = try? JSONDecoder().decode([BenchmarkResult].self, from: decodedPayload) {
            let normalized = decoded.map { $0.normalizedDeviceNameIfNeeded() }
            if normalized.map(\.deviceName) != decoded.map(\.deviceName) || decodedPayload == data {
                save(normalized, to: backend)
            }
            return normalized.sorted(by: { $0.timestamp > $1.timestamp })
        }

        if let legacyDecoded = try? JSONSerialization.jsonObject(with: decodedPayload) as? [[String: Any]] {
            let mapped = legacyDecoded.compactMap { item -> BenchmarkResult? in
                let id = (item["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
                let sessionID = (item["sessionID"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
                let deviceName = item["deviceName"] as? String ?? "Unknown Device"
                let benchmarkIntensity = item["benchmarkIntensity"] as? String ?? "Balanced"
                let note = item["note"] as? String ?? ""
                let tags = item["tags"] as? [String] ?? []
                let singleCoreScore = item["singleCoreScore"] as? Double ?? 0
                let cpuScore = item["cpuScore"] as? Double ?? 0
                let memoryScore = item["memoryScore"] as? Double ?? 0
                let memoryRawThroughputMBps = item["memoryRawThroughputMBps"] as? Double ?? memoryScore
                let ssdScore = item["ssdScore"] as? Double ?? 0
                let ssdRawCombinedMBps = item["ssdRawCombinedMBps"] as? Double ?? ssdScore
                let ssdRawReadMBps = item["ssdRawReadMBps"] as? Double ?? ssdRawCombinedMBps
                let ssdRawWriteMBps = item["ssdRawWriteMBps"] as? Double ?? ssdRawCombinedMBps
                let graphicsScore = item["graphicsScore"] as? Double ?? 0
                let overallScore = item["overallScore"] as? Double ?? 0

                let timestamp: Date
                if let timestampString = item["timestamp"] as? String,
                   let parsed = ISO8601DateFormatter().date(from: timestampString) {
                    timestamp = parsed
                } else {
                    timestamp = Date()
                }

                return BenchmarkResult(
                    id: id,
                    sessionID: sessionID,
                    deviceName: deviceName,
                    benchmarkIntensity: benchmarkIntensity,
                    note: note,
                    tags: tags,
                    isPinned: item["isPinned"] as? Bool ?? false,
                    singleCoreScore: singleCoreScore,
                    cpuScore: cpuScore,
                    memoryScore: memoryScore,
                    memoryRawThroughputMBps: memoryRawThroughputMBps,
                    ssdScore: ssdScore,
                    ssdRawCombinedMBps: ssdRawCombinedMBps,
                    ssdRawReadMBps: ssdRawReadMBps,
                    ssdRawWriteMBps: ssdRawWriteMBps,
                    graphicsBackend: item["graphicsBackend"] as? String ?? GraphicsBenchmarkBackend.legacy.rawValue,
                    graphicsScore: graphicsScore,
                    overallScore: overallScore,
                    timestamp: timestamp,
                    thermalState: item["thermalState"] as? Int ?? 0,
                    wasConnectedToPower: item["wasConnectedToPower"] as? Bool
                )
            }
            let normalized = mapped.map { $0.normalizedDeviceNameIfNeeded() }
            if normalized.map(\.deviceName) != mapped.map(\.deviceName) || decodedPayload == data {
                save(normalized, to: backend)
            }
            return normalized.sorted(by: { $0.timestamp > $1.timestamp })
        }

        return []
    }

    private static func save(_ scores: [BenchmarkResult], to backend: Backend) {
        let deduped = deduplicate(scores)
        guard let encoded = try? JSONEncoder().encode(deduped) else { return }
        let storedData = BencherCrypto.encryptStoragePayload(encoded) ?? encoded
        switch backend {
        case .local:
            UserDefaults.standard.set(storedData, forKey: localStorageKey)
        case .iCloud:
            NSUbiquitousKeyValueStore.default.set(storedData, forKey: iCloudStorageKey)
            _ = NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    private static func deduplicate(_ scores: [BenchmarkResult]) -> [BenchmarkResult] {
        var merged: [UUID: BenchmarkResult] = [:]
        for result in scores {
            if let existing = merged[result.id] {
                merged[result.id] = existing.timestamp >= result.timestamp ? existing : result
            } else {
                merged[result.id] = result
            }
        }
        return merged.values.sorted(by: { $0.timestamp > $1.timestamp })
    }

    private static func loadData(from backend: Backend) -> Data? {
        switch backend {
        case .local:
            return UserDefaults.standard.data(forKey: localStorageKey)
        case .iCloud:
            return NSUbiquitousKeyValueStore.default.data(forKey: iCloudStorageKey)
        }
    }
}

struct ExportShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ActivityView: View {
    let activityItems: [Any]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        #if canImport(UIKit)
        ActivityViewController(activityItems: activityItems)
        #elseif canImport(AppKit)
        VStack(spacing: 16) {
            if let url = activityItems.first as? URL {
                ShareLink(item: url) {
                    Label("Share Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("This export item cannot be shared on this platform.")
                    .foregroundColor(.secondary)
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(minWidth: 320)
        #else
        EmptyView()
        #endif
    }
}

#if canImport(UIKit)
private struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
#endif

// MARK: - Benchmark History JSON Document
struct BenchmarkHistoryDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var results: [BenchmarkResult]

    init(results: [BenchmarkResult]) {
        self.results = results
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            self.results = []
            return
        }
        self.results = try JSONDecoder().decode([BenchmarkResult].self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(results)
        return .init(regularFileWithContents: data)
    }
}

// MARK: - Benchmark History CSV Document
struct BenchmarkHistoryCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }

    var results: [BenchmarkResult]

    init(results: [BenchmarkResult]) {
        self.results = results
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            self.results = []
            return
        }
        self.results = try Self.parseCSV(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: Self.exportData(for: results))
    }

    static func exportData(for results: [BenchmarkResult]) -> Data {
        let header = [
            "id",
            "deviceName",
            "benchmarkIntensity",
            "singleCoreScore",
            "cpuScore",
            "memoryScore",
            "memoryRawThroughputMBps",
            "ssdScore",
            "ssdRawCombinedMBps",
            "ssdRawReadMBps",
            "ssdRawWriteMBps",
            "graphicsBackend",
            "graphicsScore",
            "overallScore",
            "timestamp",
            "thermalState",
            "wasConnectedToPower"
        ].joined(separator: ",")

        let formatter = ISO8601DateFormatter()

        let rows = results.map { result in
            let columns: [String] = [
                result.id.uuidString,
                csvEscape(result.deviceName),
                csvEscape(result.benchmarkIntensity),
                String(format: "%.0f", result.singleCoreScore),
                String(format: "%.0f", result.cpuScore),
                String(format: "%.0f", result.memoryScore),
                String(format: "%.0f", result.memoryRawThroughputMBps),
                String(format: "%.0f", result.ssdScore),
                String(format: "%.0f", result.ssdRawCombinedMBps),
                String(format: "%.0f", result.ssdRawReadMBps),
                String(format: "%.0f", result.ssdRawWriteMBps),
                csvEscape(result.graphicsBackend),
                String(format: "%.0f", result.graphicsScore),
                String(format: "%.0f", result.overallScore),
                formatter.string(from: result.timestamp),
                String(result.thermalState),
                result.wasConnectedToPower.map { $0 ? "true" : "false" } ?? ""
            ]
            return columns.joined(separator: ",")
        }

        let csv = ([header] + rows).joined(separator: "\n")
        return Data(csv.utf8)
    }

    static func parseCSV(_ data: Data) throws -> [BenchmarkResult] {
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(
                domain: "BencherCSV",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not read CSV as UTF-8 text."]
            )
        }

        let lines = string
            .components(separatedBy: CharacterSet.newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard lines.count >= 2 else { return [] }

        let rows = lines.dropFirst()
        let formatter = ISO8601DateFormatter()

        return rows.compactMap { line in
            let columns = parseCSVLine(line)
            guard columns.count >= 15 else { return nil }

            let id = UUID(uuidString: columns[0]) ?? UUID()
            let deviceName = columns[1]
            let benchmarkIntensity = columns[2].isEmpty ? "Balanced" : columns[2]
            let singleCoreScore = Double(columns[3]) ?? 0
            let cpuScore = Double(columns[4]) ?? 0
            let memoryScore = Double(columns[5]) ?? 0
            let memoryRawThroughputMBps = Double(columns[6]) ?? memoryScore
            let ssdScore = Double(columns[7]) ?? 0
            let ssdRawCombinedMBps = Double(columns[8]) ?? ssdScore
            let ssdRawReadMBps = Double(columns[9]) ?? ssdRawCombinedMBps
            let ssdRawWriteMBps = Double(columns[10]) ?? ssdRawCombinedMBps
            let hasGraphicsBackendColumn = columns.count >= 17
            let graphicsBackend = hasGraphicsBackendColumn ? columns[11] : GraphicsBenchmarkBackend.legacy.rawValue
            let graphicsScore = Double(columns[hasGraphicsBackendColumn ? 12 : 11]) ?? 0
            let overallScore = Double(columns[hasGraphicsBackendColumn ? 13 : 12]) ?? 0
            let timestamp = formatter.date(from: columns[hasGraphicsBackendColumn ? 14 : 13]) ?? Date()
            let thermalState = Int(columns[hasGraphicsBackendColumn ? 15 : 14]) ?? 0
            let wasConnectedToPower: Bool? = {
                let powerIndex = hasGraphicsBackendColumn ? 16 : 15
                guard columns.count > powerIndex else { return nil }
                switch columns[powerIndex].lowercased() {
                case "true":
                    return true
                case "false":
                    return false
                default:
                    return nil
                }
            }()

            return BenchmarkResult(
                id: id,
                sessionID: UUID(),
                deviceName: deviceName,
                benchmarkIntensity: benchmarkIntensity,
                note: "",
                tags: [],
                isPinned: false,
                singleCoreScore: singleCoreScore,
                cpuScore: cpuScore,
                memoryScore: memoryScore,
                memoryRawThroughputMBps: memoryRawThroughputMBps,
                ssdScore: ssdScore,
                ssdRawCombinedMBps: ssdRawCombinedMBps,
                ssdRawReadMBps: ssdRawReadMBps,
                ssdRawWriteMBps: ssdRawWriteMBps,
                graphicsBackend: graphicsBackend.isEmpty ? GraphicsBenchmarkBackend.legacy.rawValue : graphicsBackend,
                graphicsScore: graphicsScore,
                overallScore: overallScore,
                timestamp: timestamp,
                thermalState: thermalState,
                wasConnectedToPower: wasConnectedToPower
            )
        }
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var index = line.startIndex

        while index < line.endIndex {
            let character = line[index]

            if character == "\"" {
                let nextIndex = line.index(after: index)
                if inQuotes, nextIndex < line.endIndex, line[nextIndex] == "\"" {
                    current.append("\"")
                    index = nextIndex
                } else {
                    inQuotes.toggle()
                }
            } else if character == ",", !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(character)
            }

            index = line.index(after: index)
        }

        result.append(current)
        return result
    }
}

// MARK: - History Sort Option
enum HistorySortOption: String, CaseIterable, Identifiable {
    case dateNewest
    case dateOldest
    case scoreHighest
    case scoreLowest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dateNewest:
            return "Newest"
        case .dateOldest:
            return "Oldest"
        case .scoreHighest:
            return "Highest"
        case .scoreLowest:
            return "Lowest"
        }
    }
}

private enum HistoryFilterChipID: CaseIterable {
    case device
    case intensity
    case thermal
    case power
    case graphics
    case favourites
}

enum BencherTheme {
    static let heroGradient = LinearGradient(
        colors: [Color.blue.opacity(0.22), Color.purple.opacity(0.18)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.16), Color.white.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentChipGradient = LinearGradient(
        colors: [Color.blue.opacity(0.18), Color.purple.opacity(0.12)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

enum Haptics {
    static func success() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func warning() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    static func error() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    static func light() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Device Model Helper
enum DeviceModel {
    static func currentDeviceName() -> String {
        let identifier = currentIdentifier()
        return friendlyName(for: identifier)
    }
    
    static func normalizedDisplayName(deviceName: String) -> String {
        let trimmed = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return deviceName }

        if let identifier = extractedHardwareIdentifier(from: trimmed) {
            let resolved = friendlyName(for: identifier)
            if resolved != identifier {
                return resolved
            }
        }

        return deviceName
    }

    private static func extractedHardwareIdentifier(from name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let knownPrefixes = ["iPhone", "iPad", "MacBookAir", "MacBookPro", "Macmini", "iMac", "MacPro", "Mac"]

        for prefix in knownPrefixes {
            if trimmed.hasPrefix(prefix), trimmed.contains(",") {
                if !trimmed.contains("(") {
                    return trimmed
                }

                if let openParen = trimmed.firstIndex(of: "("),
                   let closeParen = trimmed[openParen...].firstIndex(of: ")") {
                    let candidate = String(trimmed[trimmed.index(after: openParen)..<closeParen])
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if candidate.hasPrefix(prefix) || knownPrefixes.contains(where: { candidate.hasPrefix($0) }) {
                        return candidate
                    }
                }
            }
        }

        return nil
    }

    private static func currentIdentifier() -> String {
        #if os(macOS) || targetEnvironment(macCatalyst)
        if let hwModel = sysctlString("hw.model"), !hwModel.isEmpty {
            return hwModel
        }
        #endif

        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) { cString in
                String(cString: cString)
            }
        }
    }

    private static func sysctlString(_ name: String) -> String? {
        var size: size_t = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }

        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }

    private static func friendlyName(for identifier: String) -> String {
        let map: [String: String] = [
            // iPhone
            "iPhone10,1": "iPhone 8",
            "iPhone10,2": "iPhone 8 Plus",
            "iPhone10,3": "iPhone X",
            "iPhone10,4": "iPhone 8",
            "iPhone10,5": "iPhone 8 Plus",
            "iPhone10,6": "iPhone X",
            "iPhone11,2": "iPhone XS",
            "iPhone11,4": "iPhone XS Max",
            "iPhone11,6": "iPhone XS Max",
            "iPhone11,8": "iPhone XR",
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",
            "iPhone12,8": "iPhone SE (2nd gen)",
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13",
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,6": "iPhone SE (3rd gen)",
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone18,1": "iPhone 17 Pro",
            "iPhone18,2": "iPhone 17 Pro Max",
            "iPhone18,3": "iPhone 17",

            // iPad
            "iPad8,1": "iPad Pro 11-inch (1st gen)",
            "iPad8,2": "iPad Pro 11-inch (1st gen)",
            "iPad8,3": "iPad Pro 11-inch (1st gen)",
            "iPad8,4": "iPad Pro 11-inch (1st gen)",
            "iPad8,9": "iPad Pro 11-inch (2nd gen)",
            "iPad8,10": "iPad Pro 11-inch (2nd gen)",
            "iPad13,4": "iPad Pro 11-inch (3rd gen)",
            "iPad13,5": "iPad Pro 11-inch (3rd gen)",
            "iPad13,6": "iPad Pro 11-inch (3rd gen)",
            "iPad13,7": "iPad Pro 11-inch (3rd gen)",
            "iPad14,3": "iPad Pro 11-inch (4th gen)",
            "iPad14,4": "iPad Pro 11-inch (4th gen)",
            "iPad16,3": "iPad Pro 11-inch (M4)",
            "iPad16,4": "iPad Pro 11-inch (M4)",
            "iPad8,5": "iPad Pro 12.9-inch (3rd gen)",
            "iPad8,6": "iPad Pro 12.9-inch (3rd gen)",
            "iPad8,7": "iPad Pro 12.9-inch (3rd gen)",
            "iPad8,8": "iPad Pro 12.9-inch (3rd gen)",
            "iPad8,11": "iPad Pro 12.9-inch (4th gen)",
            "iPad8,12": "iPad Pro 12.9-inch (4th gen)",
            "iPad13,8": "iPad Pro 12.9-inch (5th gen)",
            "iPad13,9": "iPad Pro 12.9-inch (5th gen)",
            "iPad13,10": "iPad Pro 12.9-inch (5th gen)",
            "iPad13,11": "iPad Pro 12.9-inch (5th gen)",
            "iPad14,5": "iPad Pro 12.9-inch (6th gen)",
            "iPad14,6": "iPad Pro 12.9-inch (6th gen)",
            "iPad16,5": "iPad Pro 13-inch (M4)",
            "iPad16,6": "iPad Pro 13-inch (M4)",
            "iPad11,3": "iPad Air (3rd gen)",
            "iPad11,4": "iPad Air (3rd gen)",
            "iPad13,1": "iPad Air (4th gen)",
            "iPad13,2": "iPad Air (4th gen)",
            "iPad13,16": "iPad Air (5th gen)",
            "iPad13,17": "iPad Air (5th gen)",
            "iPad14,8": "iPad Air 11-inch (M2)",
            "iPad14,9": "iPad Air 11-inch (M2)",
            "iPad14,10": "iPad Air 13-inch (M2)",
            "iPad14,11": "iPad Air 13-inch (M2)",
            "iPad11,6": "iPad (8th gen)",
            "iPad11,7": "iPad (8th gen)",
            "iPad12,1": "iPad (9th gen)",
            "iPad12,2": "iPad (9th gen)",
            "iPad13,18": "iPad (10th gen)",
            "iPad13,19": "iPad (10th gen)",
            "iPad11,1": "iPad mini (5th gen)",
            "iPad11,2": "iPad mini (5th gen)",
            "iPad14,1": "iPad mini (6th gen)",
            "iPad14,2": "iPad mini (6th gen)",
            "iPad16,1": "iPad mini (A17 Pro)",

            // Mac (common Apple silicon families)
            "MacBookAir10,1": "MacBook Air (M1, 2020)",
            "Mac14,2": "MacBook Air (M2, 2022)",
            "Mac14,15": "MacBook Air 15-inch (M2, 2023)",
            "Mac15,12": "MacBook Air 13-inch (M3, 2024)",
            "Mac15,13": "MacBook Air 15-inch (M3, 2024)",
            "MacBookPro17,1": "MacBook Pro 13-inch (M1, 2020)",
            "MacBookPro18,1": "MacBook Pro 16-inch (2021)",
            "MacBookPro18,2": "MacBook Pro 16-inch (2021)",
            "MacBookPro18,3": "MacBook Pro 14-inch (2021)",
            "MacBookPro18,4": "MacBook Pro 14-inch (2021)",
            "Mac14,5": "MacBook Pro 14-inch (2023)",
            "Mac14,6": "MacBook Pro 16-inch (2023)",
            "Mac14,9": "MacBook Pro 14-inch (2023)",
            "Mac14,10": "MacBook Pro 16-inch (2023)",
            "Mac15,3": "MacBook Pro 14-inch (2024)",
            "Mac15,6": "MacBook Pro 16-inch (2024)",
            "Macmini9,1": "Mac mini (M1, 2020)",
            "Mac14,3": "Mac mini (M2, 2023)",
            "Mac14,12": "Mac mini (M2 Pro, 2023)",
            "Mac16,10": "Mac mini (M4, 2024)",
            "Mac16,11": "Mac mini (M4 Pro, 2024)",
            "Mac13,1": "Mac Studio (2022)",
            "Mac13,2": "Mac Studio (2022)",
            "Mac14,13": "Mac Studio (2023)",
            "Mac14,14": "Mac Studio (2023)",
            "Mac15,7": "Mac Studio (2025)",
            "Mac15,8": "Mac Studio (2025)",
            "iMac21,1": "iMac 24-inch (M1, 2021)",
            "iMac21,2": "iMac 24-inch (M1, 2021)",
            "Mac14,7": "iMac 24-inch (M3, 2023)",
            "Mac14,8": "iMac 24-inch (M3, 2023)",
            "Mac14,16": "Mac Pro (2023)",
            "x86_64": "Simulator",
            "arm64": "Simulator"
        ]

        if let friendly = map[identifier] {
            return friendly
        }

        if identifier.hasPrefix("MacBookAir") {
            return "MacBook Air (\(identifier))"
        }
        if identifier.hasPrefix("MacBookPro") {
            return "MacBook Pro (\(identifier))"
        }
        if identifier.hasPrefix("Macmini") {
            return "Mac mini (\(identifier))"
        }
        if identifier.hasPrefix("iMac") {
            return "iMac (\(identifier))"
        }
        if identifier.hasPrefix("MacPro") || identifier.hasPrefix("Mac") {
            return "Mac (\(identifier))"
        }
        if identifier.hasPrefix("iPhone") {
            return identifier
        }
        if identifier.hasPrefix("iPad") {
            return identifier
        }

        #if os(macOS) || targetEnvironment(macCatalyst)
        return "Mac"
        #elseif canImport(UIKit)
        return UIDevice.current.model
        #else
        return "Device"
        #endif
    }
}

struct ComparisonSession: Identifiable {
    let id = UUID()
    let results: [BenchmarkResult]
}

// MARK: - Compare Selection View
struct CompareSelectionView: View {
    let scores: [BenchmarkResult]
    @Binding var selectedIDs: Set<BenchmarkResult.ID>
    let onComplete: ([BenchmarkResult]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    private var selectedResults: [BenchmarkResult] {
        scores.filter { selectedIDs.contains($0.id) }
    }

    private var filteredScores: [BenchmarkResult] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return scores }

        return scores.filter { result in
            result.deviceName.localizedCaseInsensitiveContains(trimmedSearch)
            || result.benchmarkIntensity.localizedCaseInsensitiveContains(trimmedSearch)
            || result.timestamp.formatted(date: .abbreviated, time: .shortened).localizedCaseInsensitiveContains(trimmedSearch)
            || String(format: "%.0f", result.overallScore).localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Select two benchmark runs to compare. Search by device, score, date or mode")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section("Select two results") {
                    ForEach(filteredScores) { result in
                        Button {
                            toggleSelection(for: result.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.deviceName)
                                        .font(.headline)
                                    Text(result.timestamp, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Overall: \(String(format: "%.0f", result.overallScore))")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                                if selectedIDs.contains(result.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Compare Results")
            .searchable(text: $searchText, prompt: "Search devices, scores, dates or modes")
            .toolbar {
                ToolbarItem(placement: .bencherTopBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bencherTopBarTrailing) {
                    Button("Done") {
                        if selectedResults.count == 2 {
                            onComplete(selectedResults)
                            dismiss()
                        }
                    }
                    .disabled(selectedResults.count != 2)
                }
            }
        }
    }

    private func toggleSelection(for id: BenchmarkResult.ID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            if selectedIDs.count >= 2, let first = selectedIDs.first {
                selectedIDs.remove(first)
            }
            selectedIDs.insert(id)
        }
    }

}

// MARK: - Compare Results View
struct CompareResultsView: View {
    let results: [BenchmarkResult]
    var onClose: (() -> Void)? = nil

    private var left: BenchmarkResult? { results.indices.contains(0) ? results[0] : nil }
    private var right: BenchmarkResult? { results.indices.contains(1) ? results[1] : nil }
    
    private var winnerSummary: String {
        guard let left, let right else { return "" }
        if left.overallScore == right.overallScore {
            return "These two runs are effectively tied overall."
        }
        let winner = left.overallScore > right.overallScore ? left : right
        let loser = left.overallScore > right.overallScore ? right : left
        let delta = winner.overallScore - loser.overallScore
        let percentage = loser.overallScore > 0 ? (delta / loser.overallScore) * 100.0 : 0
        return "\(winner.deviceName) is ahead overall by \(String(format: "%.0f", delta)) points (\(String(format: "%.1f", percentage))%)."
    }
    
    private var leftWinCount: Int {
        guard let left, let right else { return 0 }

        let comparisons: [(Double, Double)] = [
            (left.singleCoreScore, right.singleCoreScore),
            (left.cpuScore, right.cpuScore),
            (left.memoryScore, right.memoryScore),
            (left.ssdScore, right.ssdScore),
            (left.graphicsScore, right.graphicsScore),
            (left.overallScore, right.overallScore)
        ]

        return comparisons.filter { $0.0 > $0.1 }.count
    }

    private var rightWinCount: Int {
        guard let left, let right else { return 0 }

        let comparisons: [(Double, Double)] = [
            (left.singleCoreScore, right.singleCoreScore),
            (left.cpuScore, right.cpuScore),
            (left.memoryScore, right.memoryScore),
            (left.ssdScore, right.ssdScore),
            (left.graphicsScore, right.graphicsScore),
            (left.overallScore, right.overallScore)
        ]

        return comparisons.filter { $0.1 > $0.0 }.count
    }

    private var leftDisplayName: String {
        guard let left else { return "Run A" }
        if leftWinCount > rightWinCount {
            return "👑 \(left.deviceName)"
        }
        return left.deviceName
    }

    private var rightDisplayName: String {
        guard let right else { return "Run B" }
        if rightWinCount > leftWinCount {
            return "👑 \(right.deviceName)"
        }
        return right.deviceName
    }
    
    private var categorySummary: String {
        guard let left, let right else { return "" }

        let comparisons: [(Double, Double)] = [
            (left.singleCoreScore, right.singleCoreScore),
            (left.cpuScore, right.cpuScore),
            (left.memoryScore, right.memoryScore),
            (left.ssdScore, right.ssdScore),
            (left.graphicsScore, right.graphicsScore),
            (left.overallScore, right.overallScore)
        ]

        let leftWins = comparisons.filter { $0.0 > $0.1 }.count
        let rightWins = comparisons.filter { $0.1 > $0.0 }.count

        if leftWins == rightWins {
            return "Both runs are evenly matched across the main categories."
        }

        let winnerName = leftWins > rightWins ? left.deviceName : right.deviceName
        let winnerCount = max(leftWins, rightWins)
        return "\(winnerName) leads in \(winnerCount) of 6 main categories."
    }

    private var comparisonWarningText: String? {
        guard let left, let right else { return nil }
        return benchmarkComparisonWarning(primary: left, secondary: right)
    }

    private func displayName(for result: BenchmarkResult) -> String {
        guard results.count == 2 else { return result.deviceName }
        if result.id == results[0].id {
            return leftDisplayName
        }
        if result.id == results[1].id {
            return rightDisplayName
        }
        return result.deviceName
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comparison")
                        .font(.largeTitle.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Review two benchmark runs side by side and spot performance differences quickly.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if !winnerSummary.isEmpty {
                    Text(winnerSummary)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                colors: [.green.opacity(0.85), .blue.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                if !categorySummary.isEmpty {
                    Text(categorySummary)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BencherTheme.cardGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if let comparisonWarningText {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(comparisonWarningText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if let onClose {
                    Button {
                        onClose()
                    } label: {
                        Label("Back to History Details", systemImage: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if let left, let right {
                    HStack(alignment: .top, spacing: 16) {
                        comparisonHeader(for: left)
                        comparisonHeader(for: right)
                    }

                    ComparisonMetricRow(title: "Overall", leftValue: left.overallScore, rightValue: right.overallScore)
                    ComparisonMetricRow(title: "Single-Core", leftValue: left.singleCoreScore, rightValue: right.singleCoreScore)
                    ComparisonMetricRow(title: "Multi-Core", leftValue: left.cpuScore, rightValue: right.cpuScore)
                    ComparisonMetricRow(title: "Memory", leftValue: left.memoryScore, rightValue: right.memoryScore)
                    ComparisonMetricRow(title: "SSD", leftValue: left.ssdScore, rightValue: right.ssdScore)
                    ComparisonMetricRow(title: "Graphics", leftValue: left.graphicsScore, rightValue: right.graphicsScore)
                    ComparisonMetricRow(title: "RAM Raw MB/s", leftValue: left.memoryRawThroughputMBps, rightValue: right.memoryRawThroughputMBps)
                    ComparisonMetricRow(title: "SSD Raw Read MB/s", leftValue: left.ssdRawReadMBps, rightValue: right.ssdRawReadMBps)
                    ComparisonMetricRow(title: "SSD Raw Write MB/s", leftValue: left.ssdRawWriteMBps, rightValue: right.ssdRawWriteMBps)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                        Text("Two valid results are required for comparison.")
                            .font(.headline)
                        Text("Please return to History and select two benchmark runs.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .bencherInlineTitleDisplayMode()
    }

    @ViewBuilder
    private func comparisonHeader(for result: BenchmarkResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(displayName(for: result))
                .font(.headline)
                .foregroundColor(.white)

            Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))

            HStack(spacing: 6) {
                comparisonHeaderTag(
                    title: result.benchmarkIntensity,
                    systemImage: "dial.medium",
                    backgroundColor: Color.white.opacity(0.16)
                )

                comparisonHeaderTag(
                    title: result.graphicsBackend,
                    systemImage: "display",
                    backgroundColor: Color.white.opacity(0.16)
                )

                comparisonHeaderTag(
                    title: thermalStateText(result.thermalState),
                    systemImage: "thermometer.medium",
                    backgroundColor: result.thermalState > 0 ? Color.orange.opacity(0.35) : Color.white.opacity(0.16)
                )
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func comparisonHeaderTag(title: String, systemImage: String, backgroundColor: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private func thermalStateText(_ state: Int) -> String {
        switch state {
        case 0:
            return "Nominal"
        case 1:
            return "Fair"
        case 2:
            return "Serious"
        case 3:
            return "Critical"
        default:
            return "Unknown"
        }
    }
}

struct ComparisonMetricRow: View {
    let title: String
    let leftValue: Double
    let rightValue: Double
    
    private var delta: Double {
        rightValue - leftValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(deltaText)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(delta >= 0 ? Color.green : Color.red)
                    .clipShape(Capsule())
            }
            
            HStack(alignment: .center, spacing: 16) {
                comparisonValueCard(label: "Run A", value: leftValue, color: .blue, isWinner: leftValue > rightValue)
                comparisonValueCard(label: "Run B", value: rightValue, color: .purple, isWinner: rightValue > leftValue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func comparisonValueCard(label: String, value: Double, color: Color, isWinner: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 6) {
                Text(String(format: "%.0f", value))
                    .font(.title3.weight(.bold))
                    .foregroundColor(color)
                if isWinner {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(isWinner ? color.opacity(0.16) : color.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isWinner ? color.opacity(0.35) : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var deltaText: String {
        let sign = delta >= 0 ? "+" : ""
        let baseline = leftValue == 0 ? 0 : (delta / leftValue) * 100.0
        return "\(sign)\(String(format: "%.0f", delta)) · \(String(format: "%.1f", baseline))%"
    }
}

struct MultiDeleteHistoryView: View {
    let scores: [BenchmarkResult]
    let onDelete: (Set<UUID>) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List(scores) { result in
                Button {
                    toggle(result.id)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.deviceName)
                                .font(.headline)
                            Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Overall: \(String(format: "%.0f", result.overallScore))")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        if selectedIDs.contains(result.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Multi-Delete")
            .toolbar {
                ToolbarItem(placement: .bencherTopBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bencherTopBarTrailing) {
                    Button("Delete") {
                        onDelete(selectedIDs)
                        dismiss()
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}

// MARK: - Trends View

enum TrendTimeRange: String, CaseIterable, Identifiable {
    case sevenDays = "7D"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case allTime = "All"

    var id: String { rawValue }

    var title: String { rawValue }
}

private struct DailyTrendPoint: Identifiable {
    let date: Date
    let runs: [BenchmarkResult]

    var id: Date { date }

    var representativeRun: BenchmarkResult? {
        runs.max(by: { $0.timestamp < $1.timestamp })
    }

    var deviceName: String {
        representativeRun?.deviceName ?? "Unknown Device"
    }

    var benchmarkIntensity: String {
        representativeRun?.benchmarkIntensity ?? "Unknown"
    }

    var overallScore: Double {
        average(for: \.overallScore)
    }

    var cpuScore: Double {
        average(for: \.cpuScore)
    }

    var graphicsScore: Double {
        average(for: \.graphicsScore)
    }

    var ssdScore: Double {
        average(for: \.ssdScore)
    }

    func metricValue(for keyPath: KeyPath<BenchmarkResult, Double>) -> Double {
        average(for: keyPath)
    }

    private func average(for keyPath: KeyPath<BenchmarkResult, Double>) -> Double {
        guard !runs.isEmpty else { return 0 }
        return runs.map { $0[keyPath: keyPath] }.reduce(0, +) / Double(runs.count)
    }
}

struct TrendsView: View {
    let scores: [BenchmarkResult]
    @Binding var selectedTab: String
    @Binding var pendingHistorySelection: BenchmarkResult.ID?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var selectedDeviceFilter: String = "All Devices"
    @State private var selectedBenchmarkFilter: String = "Balanced"
    @State private var selectedGraphicsBackendFilter: String = GraphicsBenchmarkBackend.metal.rawValue
    @State private var selectedTimeRange: TrendTimeRange = .allTime
    @State private var selectedTrendDate: Date? = nil
    
    private var peakDay: DailyTrendPoint? {
        dailyTrendPoints.max(by: { $0.overallScore < $1.overallScore })
    }

    private var lowestDay: DailyTrendPoint? {
        dailyTrendPoints.min(by: { $0.overallScore < $1.overallScore })
    }

    private func peakDay(for keyPath: KeyPath<BenchmarkResult, Double>) -> DailyTrendPoint? {
        trendPoints(for: keyPath).max(by: { $0.metricValue(for: keyPath) < $1.metricValue(for: keyPath) })
    }

    private func lowestDay(for keyPath: KeyPath<BenchmarkResult, Double>) -> DailyTrendPoint? {
        trendPoints(for: keyPath).min(by: { $0.metricValue(for: keyPath) < $1.metricValue(for: keyPath) })
    }

    private func startDate(for latestDate: Date) -> Date? {
        let calendar = Calendar.current

        switch selectedTimeRange {
        case .sevenDays:
            return calendar.date(byAdding: .day, value: -7, to: latestDate)
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: latestDate)
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: latestDate)
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: latestDate)
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: latestDate)
        case .allTime:
            return nil
        }
    }

    private var chartDateDomain: ClosedRange<Date>? {
        guard selectedTimeRange != .allTime else { return nil }
        guard let latestDate = baseFilteredScores.map(\.timestamp).max(),
              let startDate = startDate(for: latestDate) else {
            return nil
        }
        return startDate...latestDate
    }

    private var baseFilteredScores: [BenchmarkResult] {
        scores.filter { result in
            let matchesDevice = selectedDeviceFilter == "All Devices" || result.deviceName == selectedDeviceFilter
            let matchesBenchmark = selectedBenchmarkFilter == "All Types" || result.benchmarkIntensity == selectedBenchmarkFilter
            let matchesGraphicsBackend = selectedGraphicsBackendFilter == "All Graphics Paths" || result.graphicsBackend == selectedGraphicsBackendFilter
            return matchesDevice && matchesBenchmark && matchesGraphicsBackend
        }
    }
    private var chronologicalScores: [BenchmarkResult] {
        let sorted = baseFilteredScores.sorted(by: { $0.timestamp < $1.timestamp })
        guard let latestDate = sorted.last?.timestamp,
              let startDate = startDate(for: latestDate) else {
            return sorted
        }
        return sorted.filter { $0.timestamp >= startDate }
    }

    private var graphicsChronologicalScores: [BenchmarkResult] {
        let sorted = baseFilteredScores.sorted(by: { $0.timestamp < $1.timestamp })
        guard let latestDate = sorted.last?.timestamp,
              let startDate = startDate(for: latestDate) else {
            return sorted
        }
        return sorted.filter { $0.timestamp >= startDate }
    }

    private var dailyTrendPoints: [DailyTrendPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: chronologicalScores) { result in
            calendar.startOfDay(for: result.timestamp)
        }

        return grouped.keys.sorted().compactMap { date in
            guard let runs = grouped[date]?.sorted(by: { $0.timestamp < $1.timestamp }) else { return nil }
            return DailyTrendPoint(date: date, runs: runs)
        }
    }

    private var dailyGraphicsTrendPoints: [DailyTrendPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: graphicsChronologicalScores) { result in
            calendar.startOfDay(for: result.timestamp)
        }

        return grouped.keys.sorted().compactMap { date in
            guard let runs = grouped[date]?.sorted(by: { $0.timestamp < $1.timestamp }) else { return nil }
            return DailyTrendPoint(date: date, runs: runs)
        }
    }

    private func trendPoints(for keyPath: KeyPath<BenchmarkResult, Double>) -> [DailyTrendPoint] {
        keyPath == \.graphicsScore ? dailyGraphicsTrendPoints : dailyTrendPoints
    }

    private var availableDevices: [String] {
        let names = Set(scores.map { $0.deviceName })
        return ["All Devices"] + names.sorted()
    }
    
    private var availableBenchmarkTypes: [String] {
        ["All Types", "Balanced", "Light", "Extreme"]
    }

    private var availableGraphicsBackends: [String] {
        ["All Graphics Paths"] + Array(Set(scores.map(\.graphicsBackend))).sorted()
    }

    private var usesPortraitTrendsFilterLayout: Bool {
#if os(iOS)
        horizontalSizeClass == .compact && verticalSizeClass == .regular
#else
        false
#endif
    }

    private var latest: DailyTrendPoint? {
        dailyTrendPoints.last
    }

    private var previous: DailyTrendPoint? {
        guard dailyTrendPoints.count >= 2 else { return nil }
        return dailyTrendPoints[dailyTrendPoints.count - 2]
    }
    
    private var selectedTrendPoint: DailyTrendPoint? {
        guard let selectedTrendDate else { return nil }
        return dailyTrendPoints.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedTrendDate) })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Performance Trends")
                        .font(.largeTitle.bold())
                    
                    trendsControlPanel
                    
                    if dailyTrendPoints.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                            
                            Text("No trend data to show")
                                .font(.headline)
                            
                            Text(emptyTrendMessage)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(BencherTheme.cardGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        summaryCards
                        overallChartSection
                        metricChartSection(title: "CPU Trend", keyPath: \.cpuScore, color: .blue)
                        metricChartSection(title: "Graphics Trend", keyPath: \.graphicsScore, color: .pink)
                        metricChartSection(title: "SSD Trend", keyPath: \.ssdScore, color: .orange)
                        recentRunsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Trends")
            .onChange(of: dailyTrendPoints.map(\.date)) { _, dates in
                if let selectedTrendDate,
                   !dates.contains(where: { Calendar.current.isDate($0, inSameDayAs: selectedTrendDate) }) {
                    self.selectedTrendDate = nil
                }
            }
        }
    }
    
    private var emptyTrendMessage: String {
        let rangeSuffix = selectedTimeRange == .allTime ? "" : " in the selected time range"

        if selectedDeviceFilter != "All Devices" && selectedBenchmarkFilter != "All Types" && selectedGraphicsBackendFilter != "All Graphics Paths" {
            return "No results yet for \(selectedDeviceFilter) using \(selectedBenchmarkFilter) mode with \(selectedGraphicsBackendFilter)\(rangeSuffix)."
        }
        if selectedDeviceFilter != "All Devices" {
            return "No results yet for \(selectedDeviceFilter)\(rangeSuffix)."
        }
        if selectedBenchmarkFilter != "All Types" {
            return "No results yet for \(selectedBenchmarkFilter) mode\(rangeSuffix)."
        }
        if selectedGraphicsBackendFilter != "All Graphics Paths" {
            return "No results yet for \(selectedGraphicsBackendFilter)\(rangeSuffix)."
        }
        if selectedTimeRange != .allTime {
            return "No results yet in the selected time range."
        }
        return "No results yet"
    }

    private var trendsControlPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Trend Controls")
                        .font(.headline)
                    Text("Choose what you want to compare and how much history appears on the charts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(10)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 10) {
                trendsFilterLabel("Comparison Filters")

                Group {
                    if usesPortraitTrendsFilterLayout {
                        VStack(spacing: 12) {
                            trendsComparisonFilterMenus
                        }
                    } else {
                        HStack(spacing: 12) {
                            trendsComparisonFilterMenus
                        }
                    }
                }

                Text("Use these filters to keep your trend view focused on runs that are easier to compare fairly.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                trendsFilterLabel("Visible Time Range")

                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TrendTimeRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                Text("Focus on recent performance or zoom out to see the bigger picture over time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BencherTheme.cardGradient)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var summaryCards: some View {
        trendsSectionCard(
            title: "Summary",
            subtitle: "A quick read on the latest movement in your current filtered trend set."
        ) {
            HStack(spacing: 12) {
                trendCard(
                    title: "Latest Overall",
                    value: latest.map { String(format: "%.0f", $0.overallScore) } ?? "—",
                    subtitle: latest.map { "\($0.deviceName) average" } ?? "No device"
                )

                trendCard(
                    title: "Change vs Previous",
                    value: changeText,
                    subtitle: "Overall score"
                )
            }
        }
    }

    private var overallChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Overall Score Trend")
                    .font(.headline)
                Spacer()
                if let latest, let previous {
                    let delta = latest.overallScore - previous.overallScore
                    let sign = delta >= 0 ? "+" : ""
                    Text("Recent Δ \(sign)\(String(format: "%.0f", delta))")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(delta >= 0 ? .green : .orange)
                }
            }
            Chart(dailyTrendPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Overall", point.overallScore)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue)

                // Only show the default point if not selected and not peak/low
                if point.id != selectedTrendPoint?.id,
                   point.id != peakDay?.id,
                   point.id != lowestDay?.id {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Overall", point.overallScore)
                    )
                    .foregroundStyle(.blue)
                }

                if let selectedTrendPoint,
                   selectedTrendPoint.id == point.id {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Overall", point.overallScore)
                    )
                    .symbolSize(120)
                    .foregroundStyle(.purple)
                }
                
                if let peakDay, peakDay.id == point.id {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Overall", point.overallScore)
                    )
                    .symbolSize(90)
                    .foregroundStyle(.green)
                    .annotation(position: .top) {
                        Text("Peak")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.14))
                            .clipShape(Capsule())
                    }
                }

                if let lowestDay, lowestDay.id == point.id {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Overall", point.overallScore)
                    )
                    .symbolSize(90)
                    .foregroundStyle(.orange)
                    .annotation(position: .bottom) {
                        Text("Low")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.14))
                            .clipShape(Capsule())
                    }
                }
            }
            .chartXScale(domain: chartDateDomain ?? (dailyTrendPoints.first?.date ?? Date())...(dailyTrendPoints.last?.date ?? Date()))
            .frame(height: 220)
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            selectOverallTrendResult(at: location, proxy: proxy, geometry: geometry)
                        }
                }
            }

            if let selectedTrendPoint {
                selectedTrendInfoCard(
                    title: "Selected Overall Day",
                    valueText: String(format: "%.0f", selectedTrendPoint.overallScore),
                    subtitle: "\(selectedTrendPoint.deviceName) average",
                    point: selectedTrendPoint,
                    metricValue: { $0.overallScore }
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private func metricChartSection(title: String, keyPath: KeyPath<BenchmarkResult, Double>, color: Color) -> some View {
        let chartPoints = trendPoints(for: keyPath)
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if chartPoints.isEmpty {
                Text(keyPath == \.graphicsScore
                     ? "No graphics runs match the current filters yet."
                     : "No trend data matches the current filters yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                Chart(chartPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(title, point.metricValue(for: keyPath))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(color)

                    if point.id != selectedTrendPoint?.id,
                       point.id != peakDay(for: keyPath)?.id,
                       point.id != lowestDay(for: keyPath)?.id {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(title, point.metricValue(for: keyPath))
                        )
                        .foregroundStyle(color)
                    }

                    if let selectedTrendPoint,
                       selectedTrendPoint.id == point.id {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(title, point.metricValue(for: keyPath))
                        )
                        .symbolSize(120)
                        .foregroundStyle(.purple)
                    }

                    if let metricPeakDay = peakDay(for: keyPath), metricPeakDay.id == point.id {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(title, point.metricValue(for: keyPath))
                        )
                        .symbolSize(90)
                        .foregroundStyle(.green)
                        .annotation(position: .top) {
                            Text("Peak")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }

                    if let metricLowestDay = lowestDay(for: keyPath), metricLowestDay.id == point.id {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(title, point.metricValue(for: keyPath))
                        )
                        .symbolSize(90)
                        .foregroundStyle(.orange)
                        .annotation(position: .bottom) {
                            Text("Low")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }
                }
                .chartXScale(domain: chartDateDomain ?? (chartPoints.first?.date ?? Date())...(chartPoints.last?.date ?? Date()))
                .frame(height: 180)
                .padding()
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                selectMetricTrendResult(at: location, proxy: proxy, geometry: geometry, keyPath: keyPath, points: chartPoints)
                            }
                    }
                }
            }

            if let selectedTrendPoint {
                selectedTrendInfoCard(
                    title: "Selected \(title) Day",
                    valueText: String(format: "%.0f", selectedTrendPoint.metricValue(for: keyPath)),
                    subtitle: "\(selectedTrendPoint.deviceName) average",
                    point: selectedTrendPoint,
                    metricValue: { $0[keyPath: keyPath] }
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var recentRunsSection: some View {
        trendsSectionCard(
            title: "Recent Runs",
            subtitle: "A quick glance at the latest individual runs behind the current trend view."
        ) {
            ForEach(chronologicalScores.reversed().prefix(5)) { result in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.deviceName)
                            .font(.headline)
                        Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(String(format: "%.0f", result.overallScore))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding()
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func trendCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.title.bold())
                .foregroundColor(.blue)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func trendsFilterLabel(_ title: String) -> some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
    }

    @ViewBuilder
    private var trendsComparisonFilterMenus: some View {
        Menu {
            ForEach(availableDevices, id: \.self) { device in
                Button {
                    selectedDeviceFilter = device
                } label: {
                    trendsMenuLabel(title: device, isSelected: selectedDeviceFilter == device)
                }
            }
        } label: {
            trendsFilterButton(title: selectedDeviceFilter, systemImage: "iphone")
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Menu {
            ForEach(availableBenchmarkTypes, id: \.self) { type in
                Button {
                    selectedBenchmarkFilter = type
                } label: {
                    trendsMenuLabel(title: type, isSelected: selectedBenchmarkFilter == type)
                }
            }
        } label: {
            trendsFilterButton(title: selectedBenchmarkFilter, systemImage: "dial.medium")
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Menu {
            ForEach(availableGraphicsBackends, id: \.self) { backend in
                Button {
                    selectedGraphicsBackendFilter = backend
                } label: {
                    trendsMenuLabel(title: backend, isSelected: selectedGraphicsBackendFilter == backend)
                }
            }
        } label: {
            trendsFilterButton(title: selectedGraphicsBackendFilter, systemImage: "display")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func trendsFilterButton(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func trendsMenuLabel(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }

    private func trendsSectionCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    //@available(iOS 16.0, *)
    private func selectOverallTrendResult(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let plotFrameAnchor = proxy.plotFrame else { return }
        let plotFrame = geometry[plotFrameAnchor]
        let relativeX = location.x - plotFrame.origin.x
        let relativeY = location.y - plotFrame.origin.y

        guard relativeX >= 0,
              relativeX <= plotFrame.size.width,
              relativeY >= 0,
              relativeY <= plotFrame.size.height,
              let selectedDate: Date = proxy.value(atX: relativeX),
              let selectedValue: Double = proxy.value(atY: relativeY) else {
            return
        }

        let nearest = dailyTrendPoints.min {
            let lhsDistance = abs($0.date.timeIntervalSince(selectedDate)) + abs($0.overallScore - selectedValue) * 120
            let rhsDistance = abs($1.date.timeIntervalSince(selectedDate)) + abs($1.overallScore - selectedValue) * 120
            return lhsDistance < rhsDistance
        }

        selectedTrendDate = nearest?.date
        if selectedTrendDate != nil {
            Haptics.light()
        }
    }

    //@available(iOS 16.0, *)
    private func selectMetricTrendResult(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy,
        keyPath: KeyPath<BenchmarkResult, Double>,
        points: [DailyTrendPoint]
    ) {
        guard let plotFrameAnchor = proxy.plotFrame else { return }
        let plotFrame = geometry[plotFrameAnchor]
        let relativeX = location.x - plotFrame.origin.x
        let relativeY = location.y - plotFrame.origin.y

        guard relativeX >= 0,
              relativeX <= plotFrame.size.width,
              relativeY >= 0,
              relativeY <= plotFrame.size.height,
              let selectedDate: Date = proxy.value(atX: relativeX),
              let selectedValue: Double = proxy.value(atY: relativeY) else {
            return
        }

        let nearest = points.min {
            let lhsDistance = abs($0.date.timeIntervalSince(selectedDate)) + abs($0.metricValue(for: keyPath) - selectedValue) * 120
            let rhsDistance = abs($1.date.timeIntervalSince(selectedDate)) + abs($1.metricValue(for: keyPath) - selectedValue) * 120
            return lhsDistance < rhsDistance
        }

        selectedTrendDate = nearest?.date
        if selectedTrendDate != nil {
            Haptics.light()
        }
    }

    @ViewBuilder
    private func selectedTrendInfoCard(
        title: String,
        valueText: String,
        subtitle: String,
        point: DailyTrendPoint,
        metricValue: @escaping (BenchmarkResult) -> Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)

                        Text("Selected")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.purple.opacity(0.14))
                            .clipShape(Capsule())
                    }

                    Text(valueText)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.blue)

                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)

                    Text(point.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(point.runs.count) run\(point.runs.count == 1 ? "" : "s")")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    openSelectedTrendResultInHistory()
                } label: {
                    Label("Open in History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            ForEach(point.runs.sorted(by: { $0.timestamp > $1.timestamp })) { result in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text(result.benchmarkIntensity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(result.graphicsBackend)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(String(format: "%.0f", metricValue(result)))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.blue)

                    if point.runs.count > 1 {
                        Button {
                            openTrendResultInHistory(result)
                        } label: {
                            Label("Open", systemImage: "arrow.up.forward.app")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BencherTheme.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func openSelectedTrendResultInHistory() {
        guard let selectedTrendPoint,
              let result = selectedTrendPoint.runs.max(by: { $0.timestamp < $1.timestamp }) else { return }
        pendingHistorySelection = result.id
        selectedTab = "history"
        Haptics.light()
    }

    private func openTrendResultInHistory(_ result: BenchmarkResult) {
        pendingHistorySelection = result.id
        selectedTab = "history"
        Haptics.light()
    }

    private var changeText: String {
        guard let latest, let previous else { return "—" }
        let delta = latest.overallScore - previous.overallScore
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", delta))"
    }
}

// MARK: - Settings View
struct SettingsView: View {
    let latestResult: BenchmarkResult?
    @AppStorage("benchmarkIntensity") private var intensity: String = "Balanced"
    @AppStorage("benchmarkRepeatCount") private var benchmarkRepeatCount: Int = 1
    @AppStorage("appAppearanceMode") private var appAppearanceMode: String = "Dark"
    @AppStorage("preferredExportFormat") private var preferredExportFormat: String = "JSON"
    @AppStorage("icloudHistorySyncEnabled") private var iCloudHistorySyncEnabled: Bool = false
    @AppStorage("graphicsBenchmarkBackend") private var graphicsBenchmarkBackend: String = GraphicsBenchmarkBackend.metal.rawValue
    @State private var includeLatestBenchmarkInFeedback: Bool = false
    @State private var feedbackMessage: String? = nil
    @State private var isShowingFeedbackAlert: Bool = false
    @State private var isShowingUpdatesSheet: Bool = false
    @Environment(\.openURL) private var openURL

    private var usesSettingsHostedUpdatesOnIOS: Bool {
        #if canImport(UIKit)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }

    var body: some View {
        NavigationStack {
            settingsContent
            .navigationTitle("Settings")
            .alert("Feedback", isPresented: $isShowingFeedbackAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(feedbackMessage ?? "No message available.")
            })
            .sheet(isPresented: $isShowingUpdatesSheet) {
                UpdatesSheetView()
            }
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        #if os(macOS)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferences")
                        .font(.largeTitle.bold())
                    Text("Choose how Bencher should look and behave by default.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                settingsSectionCard(
                    title: "Benchmark Defaults",
                    description: "These settings are applied automatically when you start a new run."
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Benchmark Mode")
                                .font(.headline)
                            Picker("Mode", selection: $intensity) {
                                Text("Light").tag("Light")
                                Text("Balanced").tag("Balanced")
                                Text("Extreme").tag("Extreme")
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            Text("This is the default benchmark mode Bencher will use when you start a new run.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stability Runs")
                                .font(.headline)
                            Picker("Stability Runs", selection: $benchmarkRepeatCount) {
                                Text("1 Run").tag(1)
                                Text("3 Runs").tag(3)
                                Text("5 Runs").tag(5)
                            }
                            .pickerStyle(.radioGroup)
                            Text("Use repeated runs to smooth out one-off fluctuations and create a more stable average result.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                settingsSectionCard(
                    title: "Appearance",
                    description: "Choose whether Bencher follows the system appearance or uses a fixed theme."
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("App Theme", selection: $appAppearanceMode) {
                            Text("System").tag("System")
                            Text("Light").tag("Light")
                            Text("Dark").tag("Dark")
                        }
                        .pickerStyle(.segmented)

                        Text("Follow your device setting or keep Bencher in light or dark mode.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                settingsSectionCard(
                    title: "Export Preferences",
                    description: "Control which file format is preselected when exporting benchmark history."
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Default Format", selection: $preferredExportFormat) {
                            Text("JSON").tag("JSON")
                            Text("CSV").tag("CSV")
                        }
                        .pickerStyle(.segmented)

                        Text("Your preferred export format will stay selected the next time you export.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                settingsSectionCard(
                    title: "Storage & Sync",
                    description: "Choose whether benchmark history stays only on this device or syncs through your iCloud account."
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Sync benchmark history with iCloud", isOn: $iCloudHistorySyncEnabled)
                            .toggleStyle(.switch)

                        Text("When this is on, Bencher adds your current history to iCloud and keeps future results in sync across devices using the same Apple ID.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                settingsSectionCard(
                    title: "Graphics Benchmark",
                    description: "Choose which graphics method Bencher uses for the graphics test."
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Graphics Backend", selection: $graphicsBenchmarkBackend) {
                            ForEach(GraphicsBenchmarkBackend.settingsOptions) { backend in
                                Text(backend.rawValue).tag(backend.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(GraphicsBenchmarkBackend.settingsHelpText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                settingsSectionCard(
                    title: "Feedback",
                    description: "Send feedback by email with optional benchmark details so problems or ideas are easier to investigate."
                ) {
                    feedbackSectionContent
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(BencherPlatformColors.systemBackground)
        #else
        Form {
            Section("Benchmark Intensity") {
                Picker("Mode", selection: $intensity) {
                    Text("Light").tag("Light")
                    Text("Balanced").tag("Balanced")
                    Text("Extreme").tag("Extreme")
                }
                .pickerStyle(.segmented)

                Text("Stored locally and used as your default benchmark intensity.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Stability Runs", selection: $benchmarkRepeatCount) {
                    Text("1 Run").tag(1)
                    Text("3 Runs").tag(3)
                    Text("5 Runs").tag(5)
                }

                Text("Use repeated runs to smooth out one-off fluctuations and create a more stable average result.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Appearance") {
                Picker("App Theme", selection: $appAppearanceMode) {
                    Text("System").tag("System")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }

                Text("Choose automatic system appearance or force light/dark mode.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Export Preferences") {
                Picker("Default Format", selection: $preferredExportFormat) {
                    Text("JSON").tag("JSON")
                    Text("CSV").tag("CSV")
                }

                Text("Settings are stored locally and will remain after restarting the app.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Storage & Sync") {
                Toggle("Sync benchmark history with iCloud", isOn: $iCloudHistorySyncEnabled)

                Text("When enabled, Bencher merges your local history into iCloud and keeps future benchmark history synced across your devices signed into the same Apple ID.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Graphics Benchmark") {
                Picker("Graphics Backend", selection: $graphicsBenchmarkBackend) {
                    ForEach(GraphicsBenchmarkBackend.settingsOptions) { backend in
                        Text(backend.rawValue).tag(backend.rawValue)
                    }
                }

                Text(GraphicsBenchmarkBackend.settingsHelpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Feedback") {
                feedbackSectionContent
            }

            if usesSettingsHostedUpdatesOnIOS {
                Section("Updates") {
                    Button {
                        isShowingUpdatesSheet = true
                    } label: {
                        Label("View Release Notes", systemImage: "clock.badge.checkmark")
                    }

                    Text("Browse recent changes and search for specific fixes or features.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        #endif
    }

    @ViewBuilder
    private var feedbackSectionContent: some View {
        Toggle("Include latest full benchmark result", isOn: $includeLatestBenchmarkInFeedback)
            .disabled(latestResult == nil)

        Text(latestResult == nil
             ? "No saved benchmark result is available yet, so only the basic device and app details will be included."
             : "If enabled, the latest saved benchmark result will be added beneath your message so it is easier to investigate issues.")
            .font(.caption)
            .foregroundColor(.secondary)

        Button {
            sendFeedback()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "envelope")
                Text("Send Feedback")
            }
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    private func settingsSectionCard<Content: View>(
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BencherTheme.cardGradient)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func sendFeedback() {
        guard let feedbackEmailAddress = BencherSupport.feedbackEmailAddress() else {
            feedbackMessage = "Bencher could not load the local encrypted feedback address."
            isShowingFeedbackAlert = true
            return
        }

        guard let subject = feedbackSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let body = feedbackBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "mailto:\(feedbackEmailAddress)?subject=\(subject)&body=\(body)") else {
            feedbackMessage = "Bencher could not create the feedback email."
            isShowingFeedbackAlert = true
            return
        }

        openURL(url)
    }

    private var feedbackSubject: String {
        "Bencher Feedback (\(appVersionString))"
    }

    private var feedbackBody: String {
        let header = """
        Bencher Feedback

        App Version: \(appVersionString)
        Device: \(DeviceModel.currentDeviceName())
        OS: \(operatingSystemVersionString)
        Preferred Graphics Path: \(graphicsBenchmarkBackend)

        Feedback:
        - 
        """

        guard includeLatestBenchmarkInFeedback, let latestResult else {
            return header
        }

        return """
        \(header)

        Latest Saved Benchmark Result
        ----------------------------
        Session ID: \(latestResult.sessionID.uuidString)
        Device: \(latestResult.deviceName)
        Recorded: \(latestResult.timestamp.formatted(date: .complete, time: .standard))
        Benchmark Mode: \(latestResult.benchmarkIntensity)
        Graphics Path: \(latestResult.graphicsBackend)
        Pinned: \(latestResult.isPinned ? "Yes" : "No")
        Thermal State: \(thermalStateText(latestResult.thermalState))
        Power State: \(powerConnectionText(latestResult.wasConnectedToPower))
        Single-Core: \(String(format: "%.0f", latestResult.singleCoreScore))
        Multi-Core: \(String(format: "%.0f", latestResult.cpuScore))
        Memory: \(String(format: "%.0f", latestResult.memoryScore))
        Memory Raw Throughput: \(String(format: "%.0f", latestResult.memoryRawThroughputMBps)) MB/s
        SSD: \(String(format: "%.0f", latestResult.ssdScore))
        SSD Raw Combined: \(String(format: "%.0f", latestResult.ssdRawCombinedMBps)) MB/s
        SSD Raw Read: \(String(format: "%.0f", latestResult.ssdRawReadMBps)) MB/s
        SSD Raw Write: \(String(format: "%.0f", latestResult.ssdRawWriteMBps)) MB/s
        Graphics: \(String(format: "%.0f", latestResult.graphicsScore))
        Overall: \(String(format: "%.0f", latestResult.overallScore))
        Performance Tier: \(latestResult.performanceTier)
        Bottleneck: \(latestResult.bottleneck)
        Notes: \(latestResult.note.isEmpty ? "None" : latestResult.note)
        Tags: \(latestResult.tags.isEmpty ? "None" : latestResult.tags.joined(separator: ", "))
        """
    }

    private var appVersionString: String {
        BencherAppMetadata.versionString
    }

    private var operatingSystemVersionString: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        #if os(macOS)
        return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #else
        return "iOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #endif
    }

    private func thermalStateText(_ state: Int) -> String {
        switch state {
        case 0: return "Nominal"
        case 1: return "Fair"
        case 2: return "Serious"
        case 3: return "Critical"
        default: return "Unknown"
        }
    }

    private func powerConnectionText(_ isConnected: Bool?) -> String {
        switch isConnected {
        case true:
            return "On AC Power"
        case false:
            return "Not on AC Power"
        default:
            return "Unknown"
        }
    }
}

struct BenchmarkRunReportView: View {
    let result: BenchmarkResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Benchmark Report")
                        .font(.largeTitle.bold())

                    Text("Your run has been saved to History. Here is a quick summary of the result.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    reportCard(title: "Overall Score", value: String(format: "%.0f", result.overallScore), color: .blue)
                    reportCard(title: "Performance Tier", value: result.performanceTier, color: .green)
                    reportCard(title: "Likely Bottleneck", value: result.bottleneck, color: .orange)
                    reportCard(title: "Benchmark Type", value: result.benchmarkIntensity, color: .purple)
                    reportCard(title: "Graphics Backend", value: result.graphicsBackend, color: .pink)
                    reportCard(title: "Thermal State", value: thermalStateText(result.thermalState), color: result.thermalState > 0 ? .orange : .green)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Summary")
                            .font(.headline)
                        Text(result.reportSummary)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Run Report")
            .toolbar {
                ToolbarItem(placement: .bencherTopBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func reportCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func thermalStateText(_ state: Int) -> String {
        switch state {
        case 0: return "Nominal"
        case 1: return "Fair"
        case 2: return "Serious"
        case 3: return "Critical"
        default: return "Unknown"
        }
    }
}

struct MetadataEditorView: View {
    @Binding var note: String
    @Binding var tagsText: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextEditor(text: $note)
                        .frame(minHeight: 120)
                }

                Section("Tags") {
                    TextField("Comma-separated tags", text: $tagsText)
                    Text("Examples: cool room, charging, after reboot")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Notes & Tags")
            .toolbar {
                ToolbarItem(placement: .bencherTopBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bencherTopBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                }
            }
        }
    }
}

struct ReferenceDevicesView: View {
    let scores: [BenchmarkResult]
    @State private var selectedResultID: BenchmarkResult.ID?
    @State private var isShowingResultPicker: Bool = false
    @State private var resultSearchText: String = ""

    private let referenceSections: [ReferenceSection] = [
        ReferenceSection(
            title: "iPhone",
            rows: [
                ReferenceEntry(name: "iPhone 12", rangeText: "~300 to 430 overall", lowerBound: 300, upperBound: 430),
                ReferenceEntry(name: "iPhone 13 Pro Max", rangeText: "~430 to 560 overall", lowerBound: 430, upperBound: 560),
                ReferenceEntry(name: "iPhone 14 Pro Max", rangeText: "~520 to 650 overall", lowerBound: 520, upperBound: 650),
                ReferenceEntry(name: "Recent Pro iPhone", rangeText: "~550 to 760 overall", lowerBound: 550, upperBound: 760),
                ReferenceEntry(name: "Recent Pro Max iPhone", rangeText: "~700 to 950 overall", lowerBound: 700, upperBound: 950)
            ]
        ),
        ReferenceSection(
            title: "iPad",
            rows: [
                ReferenceEntry(name: "iPad mini / standard iPad", rangeText: "~350 to 520 overall", lowerBound: 350, upperBound: 520),
                ReferenceEntry(name: "iPad Air", rangeText: "~450 to 650 overall", lowerBound: 450, upperBound: 650),
                ReferenceEntry(name: "iPad Pro 11/13-inch (M1)", rangeText: "~620 to 760 overall", lowerBound: 620, upperBound: 760),
                ReferenceEntry(name: "iPad Pro 11/13-inch (M2/M3)", rangeText: "~700 to 1000 overall", lowerBound: 700, upperBound: 1000),
                ReferenceEntry(name: "iPad Pro 11/13-inch (M4)", rangeText: "~1000 to 1350 overall", lowerBound: 1000, upperBound: 1350)
            ]
        ),
        ReferenceSection(
            title: "Mac",
            rows: [
                ReferenceEntry(name: "MacBook Air M1/M2", rangeText: "~750 to 1000 overall", lowerBound: 750, upperBound: 1000),
                ReferenceEntry(name: "MacBook Pro / Mac mini M-class", rangeText: "~850 to 1150 overall", lowerBound: 850, upperBound: 1150),
                ReferenceEntry(name: "High-end Apple silicon Mac", rangeText: "~1000+ overall", lowerBound: 1000, upperBound: nil)
            ]
        )
    ]

    private var sortedScores: [BenchmarkResult] {
        scores.sorted(by: { $0.timestamp > $1.timestamp })
    }

    private var selectedResult: BenchmarkResult? {
        if let selectedResultID {
            return sortedScores.first(where: { $0.id == selectedResultID })
        }
        return sortedScores.first
    }

    private var filteredScores: [BenchmarkResult] {
        let trimmedSearch = resultSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return sortedScores }

        return sortedScores.filter { result in
            result.deviceName.localizedCaseInsensitiveContains(trimmedSearch)
            || result.benchmarkIntensity.localizedCaseInsensitiveContains(trimmedSearch)
            || result.timestamp.formatted(date: .abbreviated, time: .shortened).localizedCaseInsensitiveContains(trimmedSearch)
            || String(format: "%.0f", result.overallScore).localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    referenceHero

                    if sortedScores.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "iphone.gen3")
                                .font(.system(size: 34))
                                .foregroundColor(.blue)
                            Text("No saved results yet")
                                .font(.headline)
                            Text("Run a benchmark first, then return here to compare one of your saved results against the built-in reference ranges.")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(BencherTheme.cardGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        resultPickerCard

                        if let selectedResult {
                            selectedResultSummary(selectedResult)

                            if let warningText = referenceWarningText(for: selectedResult) {
                                referenceWarningCard(text: warningText)
                            }

                            ForEach(referenceSections) { section in
                                referenceSectionCard(section, selectedResult: selectedResult)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Compare")
            .onAppear {
                if selectedResultID == nil {
                    selectedResultID = sortedScores.first?.id
                }
            }
            .onChange(of: sortedScores.map(\.id)) { _, ids in
                if let selectedResultID, !ids.contains(selectedResultID) {
                    self.selectedResultID = ids.first
                } else if self.selectedResultID == nil {
                    self.selectedResultID = ids.first
                }
            }
            .sheet(isPresented: $isShowingResultPicker) {
                NavigationStack {
                    List {
                        Section("Historic Results") {
                            ForEach(filteredScores) { result in
                                Button {
                                    selectedResultID = result.id
                                    isShowingResultPicker = false
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.deviceName)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text("\(String(format: "%.0f", result.overallScore)) overall")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.blue)
                                            Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        if selectedResultID == result.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .navigationTitle("Choose Result")
                    .searchable(text: $resultSearchText, prompt: "Search device, score, date or mode")
                    .toolbar {
                        ToolbarItem(placement: .bencherTopBarLeading) {
                            Button {
                                isShowingResultPicker = false
                            } label: {
                                Label("Close", systemImage: "xmark")
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(minWidth: 84)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                #if os(macOS)
                .frame(minWidth: 640, minHeight: 720)
                #endif
            }
        }
    }

    private var referenceHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compare Against Reference Devices")
                .font(.largeTitle.bold())
            Text("Choose one of your saved benchmark runs, then see how its overall score stacks up against broad reference bands for different Apple device classes.")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BencherTheme.cardGradient)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var resultPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Result")
                .font(.headline)
            Button {
                resultSearchText = ""
                isShowingResultPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .foregroundColor(.blue)
                    Text(selectedResult.map(referencePickerLabel(for:)) ?? "Choose a saved result")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Text("Reference ranges are broad guidance based on current references. They are not intended to be used as a strict comparison.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func selectedResultSummary(_ result: BenchmarkResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(format: "%.0f", result.overallScore))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Selected Overall Score")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    referenceChip(result.deviceName, tint: .blue)
                    referenceChip(result.benchmarkIntensity, tint: .green)
                    referenceChip(result.graphicsBackend, tint: .pink)
                }
            }

            Text(result.timestamp.formatted(date: .complete, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func referenceWarningText(for result: BenchmarkResult) -> String? {
        benchmarkComparisonWarning(primary: result)
    }

    private func referenceWarningCard(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func referenceSectionCard(_ section: ReferenceSection, selectedResult: BenchmarkResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(section.title)
                .font(.headline)

            ForEach(section.rows) { row in
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.name)
                            .font(.subheadline.weight(.semibold))
                        Text(row.rangeText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(referenceComparisonText(for: selectedResult.overallScore, reference: row))
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(referenceComparisonColor(for: selectedResult.overallScore, reference: row))
                        Text(referenceComparisonCaption(for: selectedResult.overallScore, reference: row))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(referenceComparisonColor(for: selectedResult.overallScore, reference: row).opacity(0.18), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func referenceComparisonText(for score: Double, reference: ReferenceEntry) -> String {
        if score < reference.lowerBound {
            return String(format: "%.0f below", reference.lowerBound - score)
        }
        if let upperBound = reference.upperBound, score > upperBound {
            return String(format: "%.0f above", score - upperBound)
        }
        return "Within band"
    }

    private func referenceComparisonCaption(for score: Double, reference: ReferenceEntry) -> String {
        if score < reference.lowerBound {
            return "Below this reference"
        }
        if let upperBound = reference.upperBound, score > upperBound {
            return "Above this reference"
        }
        return "Comparable range"
    }

    private func referenceComparisonColor(for score: Double, reference: ReferenceEntry) -> Color {
        if score < reference.lowerBound {
            return .orange
        }
        if let upperBound = reference.upperBound, score > upperBound {
            return .green
        }
        return .blue
    }

    private func referencePickerLabel(for result: BenchmarkResult) -> String {
        "\(result.deviceName) • \(String(format: "%.0f", result.overallScore)) • \(result.timestamp.formatted(date: .abbreviated, time: .shortened))"
    }

    private func referenceChip(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundColor(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }

}

private struct ReferenceSection: Identifiable {
    let id = UUID()
    let title: String
    let rows: [ReferenceEntry]
}

private struct ReferenceEntry: Identifiable {
    let id = UUID()
    let name: String
    let rangeText: String
    let lowerBound: Double
    let upperBound: Double?
}

// MARK: - Updates View
struct UpdatesView: View {
    var body: some View {
        NavigationStack {
            UpdatesBrowserContent()
            .navigationTitle("Updates")
        }
    }
}

private struct UpdatesSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            UpdatesBrowserContent()
                .navigationTitle("Updates")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        #endif
    }
}

private struct UpdatesBrowserContent: View {
    @State private var searchText: String = ""
    private let updates: [AppUpdateEntry] = BencherReleaseNotesEntries

    private var filteredUpdates: [AppUpdateEntry] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return updates }

        return updates.filter { update in
            update.searchableText.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var currentBuildUpdates: [AppUpdateEntry] {
        filteredUpdates.filter { $0.releaseDate == "Current Build" }
    }

    private var previousBuildUpdates: [AppUpdateEntry] {
        filteredUpdates.filter { $0.releaseDate == "Previous Build" }
    }

    private var olderBuildUpdates: [AppUpdateEntry] {
        filteredUpdates.filter { $0.releaseDate == "Older Build" }
    }

    @ViewBuilder
    private var updatesContent: some View {
        #if os(macOS)
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !currentBuildUpdates.isEmpty {
                    updateSection("Current Build", entries: currentBuildUpdates)
                }

                if !previousBuildUpdates.isEmpty {
                    updateSection("Previous Build", entries: previousBuildUpdates)
                }

                if !olderBuildUpdates.isEmpty {
                    updateSection("Older Builds", entries: olderBuildUpdates)
                }
            }
            .frame(maxWidth: 860, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(BencherPlatformColors.systemBackground)
        #else
        List {
            if filteredUpdates.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No matching updates")
                            .font(.headline)
                        Text("Try a version number, feature name or keyword from the release notes.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }

            if !currentBuildUpdates.isEmpty {
                Section("Current Build") {
                    ForEach(currentBuildUpdates) { update in
                        updateRow(update)
                    }
                }
            }

            if !previousBuildUpdates.isEmpty {
                Section("Previous Build") {
                    ForEach(previousBuildUpdates) { update in
                        updateRow(update)
                    }
                }
            }

            if !olderBuildUpdates.isEmpty {
                Section("Older Builds") {
                    ForEach(olderBuildUpdates) { update in
                        updateRow(update)
                    }
                }
            }
        }
        #endif
    }

    var body: some View {
        updatesContent
            .searchable(text: $searchText, prompt: "Search updates")
    }

    @ViewBuilder
    private func updateRow(_ update: AppUpdateEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(update.version)
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Text(update.releaseDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(update.title)
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(update.changes, id: \.self) { change in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.blue)
                            .padding(.top, 6)
                        Text(change)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func updateSection(_ title: String, entries: [AppUpdateEntry]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.semibold))

            ForEach(entries) { update in
                updateRow(update)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BencherTheme.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
}

struct AppUpdateEntry: Identifiable {
    let id = UUID()
    let version: String
    let title: String
    let releaseDate: String
    let changes: [String]

    var searchableText: String {
        ([version, title, releaseDate] + changes).joined(separator: " ")
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    let scores: [BenchmarkResult]
    @Binding var selectedTab: String
    @Binding var pendingHistoryAction: DashboardHistoryAction?

    private var latestResult: BenchmarkResult? {
        scores.sorted(by: { $0.timestamp > $1.timestamp }).first
    }

    private var previousComparableResult: BenchmarkResult? {
        guard let latestResult else { return nil }
        return comparableBenchmarkBaseline(for: latestResult, within: scores)
    }

    private var trendSummary: String {
        guard let latest = latestResult else {
            return "No benchmark history yet. Run your first benchmark to get started."
        }
        guard let previous = previousComparableResult else {
            return "No matching recent trend to show here yet."
        }

        let delta = latest.overallScore - previous.overallScore
        let sign = delta >= 0 ? "+" : ""
        return "Your latest overall score is \(sign)\(String(format: "%.0f", delta)) compared with the most recent run from the same device, benchmark mode and graphics method."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Briefing")
                        .font(.largeTitle.bold())

                    Text("A clean place to benchmark your device, compare runs and keep an eye on performance over time.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let latestResult {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Latest Result")
                                .font(.headline)

                            Text(String(format: "%.0f", latestResult.overallScore))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.blue)

                            Text("Device: \(latestResult.deviceName)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)

                            Text("Benchmark mode: \(latestResult.benchmarkIntensity)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)

                            Text("Graphics method: \(latestResult.graphicsBackend)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)

                            Text("Recorded: \(latestResult.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BencherTheme.heroGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("No benchmark yet")
                                .font(.headline)
                            Text("Run your first benchmark to start filling the dashboard with results and trend highlights.")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BencherTheme.cardGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Trend Summary")
                            .font(.headline)
                        Text(trendSummary)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BencherTheme.cardGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)

                        VStack(spacing: 12) {
                            Button {
                                selectedTab = "benchmark"
                            } label: {
                                dashboardActionRow(title: "Run Benchmark", subtitle: "Jump straight into a new benchmark run.", systemImage: "speedometer")
                            }
                            .buttonStyle(.plain)

                            Button {
                                pendingHistoryAction = .compare
                                selectedTab = "history"
                            } label: {
                                dashboardActionRow(title: "Compare", subtitle: "Open History and compare two saved runs.", systemImage: "rectangle.split.2x1")
                            }
                            .buttonStyle(.plain)

                            Button {
                                pendingHistoryAction = .export
                                selectedTab = "history"
                            } label: {
                                dashboardActionRow(title: "Export", subtitle: "Open History and choose what you want to export.", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.plain)

                            Button {
                                selectedTab = "trends"
                            } label: {
                                dashboardActionRow(title: "View Trends", subtitle: "Open Trends to explore your performance history.", systemImage: "chart.line.uptrend.xyaxis")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BencherTheme.cardGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }

    @ViewBuilder
    private func dashboardActionRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BencherTheme.accentChipGradient)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
