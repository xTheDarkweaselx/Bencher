import Foundation

enum BencherAppMetadata {
    static var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }

    static var versionString: String {
        "\(shortVersion) (\(buildNumber))"
    }
}

let BencherReleaseNotesEntries: [AppUpdateEntry] = [
    AppUpdateEntry(
        version: "V1.2",
        title: "Comparison+ Pro Max Ultra",
        releaseDate: "Current Build",
        changes: [
            "Updated comparison results so changes are easier to read, with clearer wording for same-device history and device-to-device comparisons.",
            "Added a simple Flip control at the top of the comparison view so you can quickly switch which result is treated as the starting point.",
            "Refreshed the built-in reference ranges to better match Bencher's current scoring scale across iPhone, iPad and Mac.",
            "Adjusted comparison cards on smaller screens so they fit more naturally without forcing the page wider than the display."
        ]
    ),
    AppUpdateEntry(
        version: "V1.11",
        title: "Comparison View Hotfix",
        releaseDate: "Previous Build",
        changes: [
            "Changed the comparison view from forced as landscape (meaning it shows two results to side by side all the way of the screen) to potrait.",
        ]
    ),
    AppUpdateEntry(
        version: "V1.10",
        title: "Cleaner Benchmarking & Controls",
        releaseDate: "Previous Build",
        changes: [
            "Cleaned up the Benchmark screen action buttons so the run, running and cancel controls no longer show awkward extra padding around the corners.",
            "Kept the same clear button colors while removing the default button treatment that could make the controls look boxed in.",
            "Polished the benchmark control area so it fits more naturally with the rest of the screen.",
            "Improved update search on iPad, Mac and iPhone so you can find a version, feature or fix without guessing the exact wording.",
            "Added clearer search feedback in Updates, including match counts and a friendlier empty state when nothing turns up."
        ]
    ),
    AppUpdateEntry(
        version: "V1.02",
        title: "Graphics Path Safety Pass",
        releaseDate: "Older Build",
        changes: [
            "Reworked the Metal graphics test so it no longer depends on a separate shader build step, which helps avoid cloud build issues on Mac.",
            "Added a startup graphics self-check so Bencher can confirm the Metal shader path is ready before you rely on it.",
            "Kept the graphics benchmark tied to the same checked shader source, so reliability improvements do not weaken the actual GPU test."
        ]
    ),
    AppUpdateEntry(
        version: "V1.01",
        title: "Updates, Right Where You Need Them More",
        releaseDate: "Older Build",
        changes: [
            "Adjusted the updates flow so the release notes move into Settings only on iPhone, while iPad keeps its separate Updates tab.",
            "Kept the popup-style updates browser for iPhone, so checking what changed still feels quick and tidy.",
            "Fixed the Send Feedback button on iPhone and iPad so the envelope icon shows properly again."
        ]
    ),
    AppUpdateEntry(
        version: "V1.0",
        title: "Updates, Right Where You Need Them",
        releaseDate: "Older Build",
        changes: [
            "Moved release notes into Settings on iPhone and iPad, so they are easier to find without taking up a full tab.",
            "Added a popup-style updates browser on iOS, giving release notes a cleaner in-app home that feels more natural for quick check-ins.",
            "Added search to the updates view so you can quickly look up a version number, feature or fix without scrolling through the full list."
        ]
    ),
    AppUpdateEntry(
        version: "V0.99",
        title: "Cleaner Trends on iPhone",
        releaseDate: "Older Build",
        changes: [
            "Tidied up the Trends filters on iPhone so the labels no longer get awkwardly cut off in portrait mode.",
            "Reworked that filter area to stack more naturally when space is tight, while keeping the wider layout unchanged elsewhere.",
            "Left iPad, landscape iPhone and Mac layouts alone so the fix only affects the cramped portrait setup."
        ]
    ),
    AppUpdateEntry(
        version: "V0.98",
        title: "Safer Storage & Feedback",
        releaseDate: "Older Build",
        changes: [
            "Moved the feedback contact details out of the main app code and tightened up how that information is handled behind the scenes.",
            "Added stronger protection for saved benchmark history so your results are stored more securely while still syncing and loading as expected.",
            "Smoothed out the app's read and write flow so older saved data keeps working properly after the security changes."
        ]
    ),
    AppUpdateEntry(
        version: "V0.97",
        title: "Cleaner Steel & Comparisons",
        releaseDate: "Older Build",
        changes: [
            "Tidied up the benchmark warnings so older graphics runs are explained more clearly without cluttering normal result viewing.",
            "Fixed the Mac compare and reference pickers so they open at a sensible height and actually show the full list of saved runs.",
            "Kept refining comparison tools across History, Reference and Trends so matching runs are easier to line up properly."
        ]
    ),
    AppUpdateEntry(
        version: "V0.96",
        title: "Balls of Steel",
        releaseDate: "Older Build",
        changes: [
            "Reworked the graphics benchmark so it leans more on actual GPU compute work instead of simpler copy-heavy behaviour.",
            "Improved the Metal test path to make graphics runs more dependable and less likely to fall back unexpectedly.",
            "Added clearer graphics backend labelling, so saved runs now show whether they were measured with Metal, OpenCL or the legacy path."
        ]
    ),
    AppUpdateEntry(
        version: "V0.95",
        title: "Smoother Results",
        releaseDate: "Older Build",
        changes: [
            "Improved benchmark consistency so results feel far less jumpy between different ways of installing and launching the app.",
            "Tidied up a few rough edges in the benchmark flow to make fresh installs behave more predictably.",
            "Kept polishing the Mac version so it feels a little more settled overall."
        ]
    ),
    AppUpdateEntry(
        version: "V0.94",
        title: "Mac Polish Pass",
        releaseDate: "Older Build",
        changes: [
            "Refined the Mac layout so the app feels more at home on a desktop window.",
            "Adjusted spacing and sizing in a few places to stop panels from feeling oversized or cramped.",
            "Made the settings and updates screens a bit easier on the eyes, especially on larger displays."
        ]
    ),
    AppUpdateEntry(
        version: "V0.93",
        title: "History, But Tidier",
        releaseDate: "Older Build",
        changes: [
            "Reworked the Mac history view so it behaves more naturally when resizing the window.",
            "Smoothed out the sidebar and detail layout to avoid awkward jumps while browsing old benchmark runs.",
            "Made the overall Mac navigation feel closer to a proper desktop app instead of a straight tablet carry-over."
        ]
    ),
    AppUpdateEntry(
        version: "V0.92",
        title: "Cloudy Skies with a Chance of Mac",
        releaseDate: "Older Build",
        changes: [
            "Added App Sandbox Support to allow for test builds of Bencher for MacOS.",
            "Changed project permission settings of Bencher."
        ]
    ),
    AppUpdateEntry(
        version: "V0.91",
        title: "Cloudy Skies+",
        releaseDate: "Older Build",
        changes: [
            "Changed program signing and capabilities.",
            "Increased minimum iOS requirements to run Bencher (iOS 17)."
        ]
    ),
    AppUpdateEntry(
        version: "V0.90",
        title: "Cloudy Skies",
        releaseDate: "Older Build",
        changes: [
            "Added iCloud support for storing benchmark results.",
            "Made iCloud support toggleable in settings."
        ]
    ),
    AppUpdateEntry(
        version: "V0.80",
        title: "Mac to the Future",
        releaseDate: "Older Build",
        changes: [
            "Added full MacOS support.",
            "Changed the settings view for MacOS users to make it more inline for the platforms' design philosophy.",
            "Added a new side menu bar in MacOS that is similar to the iPadOS version but with a more streamlined Mac design.",
            "Updated the presentation of updates in the MacOS version to make it look cleaner.",
            "Reversed changes on the history sidebar and detailed result view to make it look more like the iPadOS version again, implementing a new design system instead to make it workon MacOS."
        ]
    ),
    AppUpdateEntry(
        version: "V0.70",
        title: "Big Mac Energy",
        releaseDate: "Older Build",
        changes: [
            "Added MacOS Catalyst support.",
            "Added automatic update feature on device names recently added to the reference list that weren't originally",
            "Added a history sidebar and detailed result view in MacOS like the iPadOS version.",
            "Reworked History on MacOS to ensure the tab bar at the top is always visible.",
            "Changed the close button in the reference tab to be a x-mark rather than text."
        ]
    ),
    AppUpdateEntry(
        version: "V0.62",
        title: "Sheen and Polish+",
        releaseDate: "Older Build",
        changes: [
            "Added a proper cross-platform app icon.",
            "Removed an older app icon setup method."
        ]
    ),
    AppUpdateEntry(
        version: "V0.61",
        title: "Sheen and Polish",
        releaseDate: "Older Build",
        changes: [
            "Changed descriptions of functions to make them more consistent with the rest of the app.",
            "Reworked descriptions to make them more user-friendly and less programmer-esque language."
        ]
    ),
    AppUpdateEntry(
        version: "V0.60",
        title: "Reference and Compare Search Improvements",
        releaseDate: "Older Build",
        changes: [
            "Added searchable result selection to the Compare flow so large benchmark histories can be narrowed by device, score, date or mode.",
            "Reworked the Reference tab result picker into a dedicated searchable chooser for better long-term scalability with many saved runs.",
            "Restored the native searchable presentation for those picker flows after confirming the earlier lag was mainly a debug-time Xcode issue.",
            "Improved result-picking usability across comparison-focused screens without changing comparison logic or saved benchmark data."
        ]
    ),
    AppUpdateEntry(
        version: "V0.59",
        title: "Reference Tab Comparison Redesign",
        releaseDate: "Older Build",
        changes: [
            "Replaced the old static Reference Devices page with a comparison view that lets you choose a saved benchmark result.",
            "Added selected-result summary presentation in Reference so the chosen run’s score, device and benchmark mode stay visible while comparing.",
            "Added broad reference-band comparisons for iPhone, iPad and Mac ranges so saved results can be judged against practical device classes more directly.",
            "Improved the Reference tab from passive guidance into a more useful analysis surface tied to your own benchmark history."
        ]
    ),
    AppUpdateEntry(
        version: "V0.58",
        title: "Benchmark Tab Visual Refresh",
        releaseDate: "Older Build",
        changes: [
            "Redesigned the Benchmark tab with a stronger hero section, clearer progress presentation and improved visual hierarchy.",
            "Added a more polished status strip for benchmark intensity, stability runs and current run state.",
            "Improved live-results presentation so score cards and progress sections feel more intentional and easier to scan.",
            "Kept benchmark logic unchanged while making the Benchmark tab feel more polished and product-like."
        ]
    ),
    AppUpdateEntry(
        version: "V0.57",
        title: "Trends Presentation and Daily Result Refinements",
        releaseDate: "Older Build",
        changes: [
            "Grouped Trends device and time-range controls into a single cleaner control panel with clearer filter labelling.",
            "Improved Trends section-card styling so summaries, charts and recent-run areas feel more cohesive visually.",
            "Refined selected-day presentation so same-day grouped points can show all runs from that day in a cleaner expanded layout.",
            "Improved the overall Trends tab polish without changing chart calculations or benchmark data handling."
        ]
    ),
    AppUpdateEntry(
        version: "V0.56",
        title: "Power State History Tracking and Filtering",
        releaseDate: "Older Build",
        changes: [
            "Added saved power-state awareness so benchmark runs can record whether the device was on AC power when the run was captured.",
            "Added charging-state visibility in detailed saved-result views for clearer context.",
            "Added a new History secondary filter for power state alongside device, intensity and thermal filters.",
            "Extended benchmark import and export support so saved power-state information remains portable."
        ]
    ),
    AppUpdateEntry(
        version: "V0.55",
        title: "Trends Daily Aggregation and Same-Day Drilldown",
        releaseDate: "Older Build",
        changes: [
            "Changed Trends charts so multiple benchmark runs on the same day are grouped into one daily average point instead of clumping or laddering.",
            "Updated selected Trend points to represent the day-average score for that date rather than only one underlying run.",
            "Added day-level drilldown so selecting a grouped day can still show every individual run captured on that date.",
            "Improved the path from grouped trend selection back into History so individual same-day runs remain accessible."
        ]
    ),
    AppUpdateEntry(
        version: "V0.54",
        title: "Benchmark Styling Simplification and History Menu Stability",
        releaseDate: "Older Build",
        changes: [
            "Removed the old full-screen benchmark gradient background so the Benchmark tab now respects the app’s light and dark appearance more naturally.",
            "Updated benchmark cards and summary surfaces to use cleaner adaptive materials instead of the older gradient-heavy presentation.",
            "Refined History filter and action menus to reduce UIKit context-menu warnings seen during first interaction in development builds.",
            "Improved visual consistency and interaction stability across Benchmark and History without changing saved results or benchmark scoring."
        ]
    ),
    AppUpdateEntry(
        version: "V0.53",
        title: "Trends Time-Range Controls and Selection Accuracy",
        releaseDate: "Older Build",
        changes: [
            "Added Trends time-range filtering with 7D, 1M, 3M, 6M, 1Y and All options.",
            "Updated Trends chart scaling so changing the selected time range also updates the visible chart domain.",
            "Improved trend-point selection accuracy by using both horizontal and vertical proximity when choosing the nearest benchmark run.",
            "Fixed metric-chart Peak and Low annotations so they now reflect the active metric instead of incorrectly using overall score.",
            "Updated selected trend markers so they render correctly when the chosen point is also the Peak or Low result.",
            "Added a clearer Selected badge to trend result summary cards beneath the charts.",
            "Improved the jump from Trends into History so selected chart runs can still open the matching detailed result view reliably.",
            "Improved compact detail layouts by fixing missing horizontal padding in benchmark detail presentation on iPhone."
        ]
    ),
    AppUpdateEntry(
        version: "V0.52",
        title: "Interactive Trends and Comparison Refinements",
        releaseDate: "Older Build",
        changes: [
            "Added interactive Trends chart selection so tapping chart points now highlights the nearest benchmark run.",
            "Added selected-run summary cards beneath trend charts showing the relevant metric value, device and timestamp.",
            "Added an Open in History action from Trends so selected chart runs can jump directly into the matching History detail view.",
            "Updated History and Trends coordination so selected trend results can open correctly on both iPhone and iPad flows.",
            "Improved Compare view presentation by removing the redundant plain Compare title and keeping the richer Comparison heading.",
            "Added crowned device names in the comparison header so the run leading the most main categories is clearly marked.",
            "Improved comparison header chips so benchmark mode and thermal state stay on one line more reliably.",
            "Refined comparison metric presentation by removing stray outer styling and keeping winner emphasis cleaner and more consistent.",
            "Updated Trends chart hit-testing for modern iOS APIs by safely unwrapping plotFrame before using it."
        ]
    ),
    AppUpdateEntry(
        version: "V0.51",
        title: "History Navigation and Detail View Refinements",
        releaseDate: "Older Build",
        changes: [
            "Refined compact History result opening so iPhone now presents detailed benchmark results more reliably again.",
            "Replaced the broken compact History detail popup flow with a cleaner full-screen presentation for better stability and scrolling.",
            "Improved iPhone History result navigation so tapping a saved run no longer leaves detail presentation frozen or malformed.",
            "Polished the History detail presentation and overall interaction flow between saved results and detailed benchmark analysis.",
            "Adjusted the detailed result Report Card pills so Tier and Bottleneck cards feel less squashed on both iPhone and iPad.",
            "Refined iPad History header controls so Compare and Export remain on one line more reliably in the sidebar."
        ]
    ),
    AppUpdateEntry(
        version: "V0.50",
        title: "Phase 3 Visual Polish Completion",
        releaseDate: "Older Build",
        changes: [
            "Completed the Phase 3 polish pass across Benchmark, Dashboard, History, Trends and detailed result views.",
            "Improved the overall app feel with more consistent cards, chips, gradients, haptics and feedback patterns.",
            "Refined both iPhone and iPad History layouts so the interface feels more native to each device class.",
            "Improved the app from a functional benchmark tool into a more polished performance-analysis experience."
        ]
    ),
    AppUpdateEntry(
        version: "V0.49",
        title: "History Layout Adaptation for iPhone and iPad",
        releaseDate: "Older Build",
        changes: [
            "Updated the History header area so controls now scroll away naturally with content on iPhone instead of staying fixed at the top.",
            "Added a more compact iPhone-only History header layout with tighter title, control and chip spacing.",
            "Refined the iPad History header so Compare and Export stay on one line more reliably.",
            "Improved History layout behaviour across different size classes without changing core workflows."
        ]
    ),
    AppUpdateEntry(
        version: "V0.48",
        title: "History Selection Styling and iPad Detail Polish",
        releaseDate: "Older Build",
        changes: [
            "Replaced the default iPad blue List selection highlight with a softer custom selection treatment.",
            "Added a subtle border glow, shadow and lift effect to the selected History row for a more premium feel.",
            "Improved selected-row emphasis without overwhelming the rest of the History list.",
            "Refined History detail presentation so selection and focus feel cleaner on larger screens."
        ]
    ),
    AppUpdateEntry(
        version: "V0.47",
        title: "History Row Card Polish",
        releaseDate: "Older Build",
        changes: [
            "Redesigned History rows into richer card-style layouts with stronger hierarchy for score, device, date and status information.",
            "Added reusable History status chips and tag chips for a cleaner, more glanceable presentation.",
            "Improved favourite visibility, benchmark intensity visibility and thermal-state presentation in History rows.",
            "Improved the visual consistency between History rows and the rest of the app’s newer card-based design."
        ]
    ),
    AppUpdateEntry(
        version: "V0.46",
        title: "Detailed Result View Visual Alignment",
        releaseDate: "Older Build",
        changes: [
            "Polished the detailed benchmark result view so it now visually aligns more closely with the upgraded History rows.",
            "Upgraded the result summary card with clearer hero styling, richer status chips and improved metadata presentation.",
            "Converted Notes & Tags in detailed results to chip-based presentation for stronger consistency.",
            "Unified detailed result cards, report sections and metric cards with the shared app styling system."
        ]
    ),
    AppUpdateEntry(
        version: "V0.45",
        title: "Import Transparency and Better Result Messaging",
        releaseDate: "Older Build",
        changes: [
            "Improved import completion messaging so the pop-up now shows how many results were newly added versus ignored as duplicates.",
            "Made history import behaviour more transparent when importing files that overlap with locally stored benchmark records.",
            "Improved user confidence in import operations by reporting actual merge outcomes instead of only generic success messages."
        ]
    ),
    AppUpdateEntry(
        version: "V0.44",
        title: "Shared Theme System and Visual Consistency",
        releaseDate: "Older Build",
        changes: [
            "Added a shared BencherTheme system for hero gradients, card gradients and accent chip gradients.",
            "Improved visual consistency across Dashboard, History, Trends, Score Cards and detail screens.",
            "Reduced one-off styling differences by centralising core gradient and card presentation patterns."
        ]
    ),
    AppUpdateEntry(
        version: "V0.43",
        title: "Animation and Haptics Feedback Pass",
        releaseDate: "Older Build",
        changes: [
            "Added animated Score Card appearance so benchmark metrics now enter more smoothly.",
            "Added subtle haptic feedback for benchmark completion, export readiness, import success, import failure and undo restore.",
            "Improved tactile feedback and responsiveness so key actions feel more deliberate and polished."
        ]
    ),
    AppUpdateEntry(
        version: "V0.42",
        title: "Dashboard and Trends Presentation Polish",
        releaseDate: "Older Build",
        changes: [
            "Updated Dashboard cards and quick actions to use the shared visual styling system.",
            "Improved the Trends empty state with a richer card-style presentation instead of plain text.",
            "Improved Dashboard and Trends consistency so both now feel more integrated with the wider app design language."
        ]
    ),
    AppUpdateEntry(
        version: "V0.41",
        title: "Phase 3 Polish Foundations",
        releaseDate: "Older Build",
        changes: [
            "Started the Phase 3 polish pass focused on visual consistency, empty states, animation and feedback quality.",
            "Began refining the app from a feature-complete prototype into a more polished end-user product.",
            "Established the groundwork for broader card, chip, gradient and interaction improvements across the app."
        ]
    ),
    AppUpdateEntry(
        version: "V0.40",
        title: "Undo for Deletions and Favourite Terminology Cleanup",
        releaseDate: "Older Build",
        changes: [
            "Added an Undo action for the most recently deleted history item or deleted set of history items.",
            "Added a restore banner in History so recently deleted benchmark runs can be brought back quickly.",
            "Standardised user-facing naming from pinning to favouriting while keeping storage compatible internally.",
            "Updated visible History indicators and swipe actions to use favourite star icons for consistency."
        ]
    ),
    AppUpdateEntry(
        version: "V0.39",
        title: "Cleaner History Layout and Reduced Menu Clutter",
        releaseDate: "Older Build",
        changes: [
            "Moved Compare and Export out of the ellipsis menu and into visible History actions.",
            "Made sort controls visible at the top of History using a segmented control for faster access.",
            "Moved core filters into a visible horizontal filter row instead of hiding them inside the menu.",
            "Reduced History menu complexity so it now focuses on lower-frequency actions such as import, multi-delete and delete all."
        ]
    ),
    AppUpdateEntry(
        version: "V0.38",
        title: "History Filter Chips and Empty-State Improvements",
        releaseDate: "Older Build",
        changes: [
            "Added reusable filter chips for device, benchmark intensity, thermal state and favourites-only filtering.",
            "Improved History empty states so users get clearer guidance when no history matches the current search or filters.",
            "Improved top-of-screen History controls for iPad and compact layouts by reducing visual crowding and truncation."
        ]
    ),
    AppUpdateEntry(
        version: "V0.37",
        title: "History Search and Advanced Filtering",
        releaseDate: "Older Build",
        changes: [
            "Added History search across device name, notes and tags.",
            "Added History filters for device, benchmark intensity and thermal state.",
            "Added a favourites-only History filter for quickly isolating important benchmark runs.",
            "Updated History selection and detail behaviour so filtered history remains browsable and stable."
        ]
    ),
    AppUpdateEntry(
        version: "V0.36",
        title: "Favourites and Pinning Support",
        releaseDate: "Older Build",
        changes: [
            "Added favourite support for benchmark runs while keeping older saved history readable.",
            "Added swipe actions to favourite or unfavourite runs directly from History.",
            "Added favourite indicators in History rows and detailed benchmark results.",
            "Improved benchmark metadata persistence so favourite state is retained across saves, reloads and imports."
        ]
    ),
    AppUpdateEntry(
        version: "V0.35",
        title: "History Multi-Delete Workflow",
        releaseDate: "Older Build",
        changes: [
            "Added a dedicated multi-delete screen for removing several benchmark runs in one action.",
            "Added multi-select deletion confirmation flow with clear visual selection feedback.",
            "Improved History maintenance for larger saved benchmark libraries by reducing one-by-one deletion effort."
        ]
    ),
    AppUpdateEntry(
        version: "V0.34",
        title: "Delete All History Management",
        releaseDate: "Older Build",
        changes: [
            "Added Delete All History as a dedicated destructive action with confirmation.",
            "Improved History state cleanup when all benchmark runs are removed, including selection and comparison reset behaviour.",
            "Improved long-term history maintenance for users who want to reset benchmark archives quickly."
        ]
    ),
    AppUpdateEntry(
        version: "V0.33",
        title: "Dashboard to History Action Handoff",
        releaseDate: "Older Build",
        changes: [
            "Improved Dashboard quick actions so Compare and Export now launch the intended History workflows after tab switching.",
            "Added shared pending History action handling to coordinate navigation-driven actions more reliably.",
            "Improved Dashboard to History flow so quick actions behave more like direct commands instead of simple tab jumps."
        ]
    ),
    AppUpdateEntry(
        version: "V0.32",
        title: "History Sort Labelling and Usability Refinements",
        releaseDate: "Older Build",
        changes: [
            "Shortened History sort labels to Newest, Oldest, Highest and Lowest to prevent segmented control truncation.",
            "Improved top-level History usability on tighter widths by reducing control text overflow.",
            "Improved visual consistency between sort controls and the new visible History management actions."
        ]
    ),
    AppUpdateEntry(
        version: "V0.31",
        title: "Phase 2 History Management Foundations",
        releaseDate: "Older Build",
        changes: [
            "Started the Phase 2 History management work focused on search, filtering, favourites and safer deletion workflows.",
            "Expanded benchmark history records to support richer management features while keeping older saved data working.",
            "Improved History from a simple archive into a more powerful benchmark management surface."
        ]
    ),
    AppUpdateEntry(
        version: "V0.3",
        title: "Reference Devices, Run Reports and Notes & Tags",
        releaseDate: "Older Build",
        changes: [
            "Added a new Reference Devices tab with broad guidance ranges for iPhone, iPad and Mac classes.",
            "Added a post-run Benchmark Report screen that appears after a benchmark completes and summarises the result.",
            "Added editable notes and tags for benchmark runs, including a dedicated editor from the History screen.",
            "Extended benchmark history records with session IDs for stronger long-term metadata and grouping support.",
            "Added a Report Card section in detailed benchmark results with performance tier, bottleneck detection and richer guidance.",
            "Improved score card visuals with richer gradient styling and more polished card backgrounds.",
            "Improved device-aware reference guidance so detailed results now present ranges more fairly based on detected device class."
        ]
    ),
    AppUpdateEntry(
        version: "V0.22",
        title: "Smarter Export Options, Faster Exporting and Cleaner History Actions",
        releaseDate: "Older Build",
        changes: [
            "Updated export so you can choose how many saved results to export, including the last 1, 5, 10, 15, 20 or all available results.",
            "Improved export performance by moving export preparation off the main thread for both JSON and CSV export.",
            "Added a visible export progress banner so the app shows when an export is being prepared.",
            "Improved History toolbar layout on iPad by grouping Sort, Export, Import and Compare into a single Actions menu.",
            "Fixed export reliability using a share-sheet based export flow backed by temporary files.",
            "Tidied CSV export generation for better long-term efficiency and reduced unnecessary processing overhead.",
            "Cleaned up remaining file I/O warnings in the SSD benchmark implementation."
        ]
    ),
    AppUpdateEntry(
        version: "V0.21",
        title: "Additional Export and Import Formats",
        releaseDate: "Older Build",
        changes: [
            "Added CSV export support alongside JSON export.",
            "Updated the Settings tab so the preferred export format can now be set to JSON or CSV.",
            "Extended import support so benchmark history can now be imported from any supported format, including JSON and CSV.",
            "Improved history portability by allowing the same benchmark records to move between different export/import file types.",
            "Added different messages for various device thermal levels when running benchmarks."
        ]
    ),
    AppUpdateEntry(
        version: "V0.20",
        title: "History Deletion, Device Filtering and Comparison Visual Refresh",
        releaseDate: "Older Build",
        changes: [
            "Added swipe-to-delete for individual benchmark history results directly from the History list.",
            "Improved History state handling so deleting selected or compared runs safely clears related comparison state.",
            "Added device-type filtering in Trends so you can switch between devices such as iPhone, iPad and Mac when reviewing performance history.",
            "Improved Trends empty-state messaging so filtered views clearly show when no runs exist for the selected device.",
            "Refreshed the comparison screen with more colourful visuals, including gradient headers, coloured result cards and clearer metric presentation.",
            "Improved comparison readability with stronger spacing, better visual hierarchy and clearer separation between the two benchmark runs."
        ]
    ),
    AppUpdateEntry(
        version: "V0.17",
        title: "Comparison UX Fixes and Layout Improvements",
        releaseDate: "Older Build",
        changes: [
            "Fixed an issue where the comparison screen would fail to open on the first attempt on compact devices.",
            "Improved the comparison flow so results reliably open after selecting two benchmark runs.",
            "Adjusted comparison metric layout so values align correctly beneath each benchmark header.",
            "Refined spacing and indentation of comparison results for better readability and visual hierarchy."
        ]
    ),
    AppUpdateEntry(
        version: "V0.16",
        title: "Benchmark Test Type Tracking",
        releaseDate: "Older Build",
        changes: [
            "Added benchmark test type tracking so each run now records whether it was Light, Balanced or Extreme.",
            "Added the saved test type to History rows so you can see what benchmark mode was used for each run.",
            "Added the saved test type to the detailed result view for clearer context when reviewing previous benchmarks.",
            "Extended saved benchmark history so the selected benchmark mode is preserved locally and remains import/export compatible."
        ]
    ),
    AppUpdateEntry(
        version: "V0.15",
        title: "Compare Mode, Rich Trends, Appearance Settings and Thermal Visibility",
        releaseDate: "Older Build",
        changes: [
            "Added a proper compare mode flow where selecting two benchmark runs and pressing Done opens a split comparison view.",
            "Added side-by-side metric comparison for overall, CPU, memory, SSD, graphics and raw RAM / SSD readings.",
            "Added a quick return path from comparison back to the default History detail view.",
            "Greatly expanded the Trends tab with summary cards, overall trend chart, CPU trend chart, graphics trend chart, SSD trend chart and recent runs.",
            "Added local persistence for appearance settings and benchmark preferences using AppStorage.",
            "Added app appearance selection with System, Light and Dark modes.",
            "Improved History so it now shows when thermals may have affected benchmark performance.",
            "Added thermal state visibility in the detailed result view, including a throttling warning for affected runs.",
            "Expanded the compare and trends experience so the app now behaves more like a performance analysis tool rather than only a benchmark runner."
        ]
    ),
    AppUpdateEntry(
        version: "V0.10",
        title: "Trends, Insights, Settings and Update History",
        releaseDate: "Older Build",
        changes: [
            "Added a Trends tab to start tracking benchmark performance over time.",
            "Added a Settings tab with benchmark intensity options.",
            "Added thermal awareness so warm devices can warn that results may be reduced.",
            "Added an insights panel in detailed benchmark results.",
            "Added percentile-style performance guidance.",
            "Added history sorting by newest, oldest, highest score and lowest score.",
            "Improved history records with device name and raw RAM / SSD readings.",
            "Improved SSD benchmarking and score calibration.",
            "Added this Updates tab so users can review what changed in each release."
        ]
    )
]
