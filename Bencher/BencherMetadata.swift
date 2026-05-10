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
        version: "V1.40",
        title: "Top Trumps, Top Bumps",
        releaseDate: "Current Build",
        changes: [
            "Added a new top 10 leaderboard showing your best historic benchmarks.",
            "Improved the Mac leaderboard popup so it stays comfortably within the app window with better padding.",
            "Fixed benchmark cancellation so cancelled runs reset immediately and no longer only stop after the current part of the test is complete."
        ]
    ),
    AppUpdateEntry(
        version: "V1.31",
        title: "MacOS Release Version",
        releaseDate: "Previous Build",
        changes: [
            "Reduced permission requirements on Bencher in-line with the iOS app.",
        ]
    ),
    AppUpdateEntry(
        version: "V1.30",
        title: "Release Version Polish",
        releaseDate: "Previous Build",
        changes: [
            "Polished older update notes so the release history reads more naturally and feels less like internal development notes.",
            "Cleaned up wording around older Mac, iCloud, History, Trends, Reference and export changes while keeping the original update titles intact.",
            "Improved older benchmark detail warnings so legacy graphics results are explained clearly when you are only viewing a saved result.",
            "Kept the comparison-specific warning for actual side-by-side comparisons, where setup differences still matter.",
            "Added a clearer iCloud sign-in message when sync is enabled without an iCloud account, while keeping benchmark history safely local until iCloud is available."
        ]
    ),
    AppUpdateEntry(
        version: "V1.20",
        title: "Comparison+ Pro Max Ultra",
        releaseDate: "Older Build",
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
        releaseDate: "Older Build",
        changes: [
            "Fixed the comparison view on smaller screens so results no longer feel forced into a wide side-by-side layout.",
        ]
    ),
    AppUpdateEntry(
        version: "V1.10",
        title: "Cleaner Benchmarking & Controls",
        releaseDate: "Older Build",
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
            "Prepared the Mac version for safer TestFlight builds with the right sandbox permissions in place.",
            "Cleaned up the app's Mac permission setup so it behaves more predictably during testing."
        ]
    ),
    AppUpdateEntry(
        version: "V0.91",
        title: "Cloudy Skies+",
        releaseDate: "Older Build",
        changes: [
            "Updated Bencher's signing and app capabilities to support the next stage of testing.",
            "Raised the minimum iOS version so the app can rely on the newer system features it now uses."
        ]
    ),
    AppUpdateEntry(
        version: "V0.90",
        title: "Cloudy Skies",
        releaseDate: "Older Build",
        changes: [
            "Added optional iCloud support for keeping benchmark history available across your devices.",
            "Added a Settings switch so you can choose whether Bencher stores history locally or syncs it with iCloud."
        ]
    ),
    AppUpdateEntry(
        version: "V0.80",
        title: "Mac to the Future",
        releaseDate: "Older Build",
        changes: [
            "Added full Mac support so Bencher feels at home on desktop as well as iPhone and iPad.",
            "Reworked Settings on Mac so it feels more natural in a desktop window.",
            "Added a cleaner Mac sidebar for moving between the main parts of the app.",
            "Polished the Updates screen on Mac so release notes are easier to read.",
            "Refined History on Mac so the sidebar and detail view feel closer to the iPad layout while still fitting a desktop window."
        ]
    ),
    AppUpdateEntry(
        version: "V0.70",
        title: "Big Mac Energy",
        releaseDate: "Older Build",
        changes: [
            "Brought Bencher to Mac through Catalyst as the first step toward a proper desktop version.",
            "Improved device naming so newer reference devices can be recognised more smoothly.",
            "Added a Mac History layout with a sidebar and detailed result view, similar to the iPad experience.",
            "Adjusted History on Mac so navigation stays easier to reach while browsing saved results.",
            "Changed the Reference close button to a cleaner x-mark icon."
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
            "Rewrote several explanations so the app speaks more consistently from screen to screen.",
            "Made benchmark descriptions easier to understand without needing technical background."
        ]
    ),
    AppUpdateEntry(
        version: "V0.60",
        title: "Reference and Compare Search Improvements",
        releaseDate: "Older Build",
        changes: [
            "Added search to the Compare picker so large histories are easier to narrow by device, score, date or mode.",
            "Gave the Reference result picker its own searchable chooser, making it much easier to use with lots of saved runs.",
            "Brought back the native search presentation once it was clear the earlier lag was only showing up during development builds.",
            "Made result picking feel smoother across comparison screens without changing any saved benchmark data."
        ]
    ),
    AppUpdateEntry(
        version: "V0.59",
        title: "Reference Tab Comparison Redesign",
        releaseDate: "Older Build",
        changes: [
            "Replaced the old static Reference Devices page with a comparison view that lets you choose a saved benchmark result.",
            "Kept the chosen run's score, device and benchmark mode visible while you compare it against reference ranges.",
            "Added broad iPhone, iPad and Mac reference bands so saved results are easier to place in context.",
            "Turned Reference from a static guide into a more useful view tied to your own benchmark history."
        ]
    ),
    AppUpdateEntry(
        version: "V0.58",
        title: "Benchmark Tab Visual Refresh",
        releaseDate: "Older Build",
        changes: [
            "Refreshed the Benchmark tab with a clearer opening section and easier-to-follow progress display.",
            "Added a cleaner status strip for benchmark mode, stability runs and current run state.",
            "Made live results easier to scan while a benchmark is running.",
            "Kept the benchmark itself unchanged while making the screen feel more polished."
        ]
    ),
    AppUpdateEntry(
        version: "V0.57",
        title: "Trends Presentation and Daily Result Refinements",
        releaseDate: "Older Build",
        changes: [
            "Grouped the Trends device and time filters into a cleaner control area.",
            "Polished Trends cards so summaries, charts and recent runs feel more connected.",
            "Made grouped same-day results easier to open and review.",
            "Improved the look of Trends without changing how scores are calculated."
        ]
    ),
    AppUpdateEntry(
        version: "V0.56",
        title: "Power State History Tracking and Filtering",
        releaseDate: "Older Build",
        changes: [
            "Saved whether a benchmark was run on battery or while connected to power.",
            "Showed power state in detailed results so each run has a little more context.",
            "Added a History filter for power state alongside device, mode and thermal filters.",
            "Included power-state details when importing or exporting benchmark history."
        ]
    ),
    AppUpdateEntry(
        version: "V0.55",
        title: "Trends Daily Aggregation and Same-Day Drilldown",
        releaseDate: "Older Build",
        changes: [
            "Grouped multiple runs from the same day into one daily average point so charts are easier to read.",
            "Made selected trend points represent the day's average instead of just one run.",
            "Added a way to open a grouped day and still see every run from that date.",
            "Kept individual same-day runs easy to reach from Trends and History."
        ]
    ),
    AppUpdateEntry(
        version: "V0.54",
        title: "Benchmark Styling Simplification and History Menu Stability",
        releaseDate: "Older Build",
        changes: [
            "Removed the old full-screen benchmark gradient background so the Benchmark tab now respects the app’s light and dark appearance more naturally.",
            "Updated benchmark cards to use cleaner materials instead of the older gradient-heavy look.",
            "Tidied History filter and action menus so they behave more smoothly.",
            "Improved consistency across Benchmark and History without changing saved results or benchmark scoring."
        ]
    ),
    AppUpdateEntry(
        version: "V0.53",
        title: "Trends Time-Range Controls and Selection Accuracy",
        releaseDate: "Older Build",
        changes: [
            "Added Trends time-range filtering with 7D, 1M, 3M, 6M, 1Y and All options.",
            "Updated Trends chart scaling so changing the selected time range also updates the visible chart domain.",
            "Made tapping points on Trends charts feel more accurate.",
            "Fixed Peak and Low labels so they match the metric currently being viewed.",
            "Cleaned up selected chart markers, including cases where the selected run is also the Peak or Low point.",
            "Added a clearer Selected badge beneath the charts.",
            "Made it more reliable to jump from a selected Trends point into the matching History result.",
            "Fixed missing side padding in detailed benchmark results on iPhone."
        ]
    ),
    AppUpdateEntry(
        version: "V0.52",
        title: "Interactive Trends and Comparison Refinements",
        releaseDate: "Older Build",
        changes: [
            "Added interactive Trends chart selection so tapping chart points now highlights the nearest benchmark run.",
            "Added selected-run cards beneath trend charts with the score, device and time for the highlighted run.",
            "Added an Open in History action from Trends so selected chart runs can jump directly into the matching History detail view.",
            "Made selected Trends results open correctly from both iPhone and iPad layouts.",
            "Cleaned up the Compare screen heading.",
            "Marked the run leading the most categories with a crown in the comparison header.",
            "Improved comparison chips so benchmark mode and thermal state fit better.",
            "Made comparison metric cards cleaner and easier to read.",
            "Improved Trends chart tapping for newer iOS versions."
        ]
    ),
    AppUpdateEntry(
        version: "V0.51",
        title: "History Navigation and Detail View Refinements",
        releaseDate: "Older Build",
        changes: [
            "Made saved History results open more reliably on iPhone.",
            "Moved detailed results to a cleaner full-screen view on compact screens for better scrolling.",
            "Fixed cases where opening a saved run could leave the detail view stuck or awkwardly presented.",
            "Polished the flow between History and detailed benchmark analysis.",
            "Gave Report Card pills more breathing room on iPhone and iPad.",
            "Adjusted the iPad History header so Compare and Export fit more comfortably."
        ]
    ),
    AppUpdateEntry(
        version: "V0.50",
        title: "Phase 3 Visual Polish Completion",
        releaseDate: "Older Build",
        changes: [
            "Finished a broad polish pass across Benchmark, Dashboard, History, Trends and detailed results.",
            "Made cards, chips, gradients, haptics and feedback feel more consistent across the app.",
            "Refined History on both iPhone and iPad so each layout feels more natural.",
            "Moved Bencher closer to a polished performance app rather than just a working benchmark tool."
        ]
    ),
    AppUpdateEntry(
        version: "V0.49",
        title: "History Layout Adaptation for iPhone and iPad",
        releaseDate: "Older Build",
        changes: [
            "Updated the History header area so controls now scroll away naturally with content on iPhone instead of staying fixed at the top.",
            "Added a tighter iPhone History header so the screen feels less crowded.",
            "Refined the iPad History header so Compare and Export stay on one line more reliably.",
            "Improved History layouts across screen sizes without changing the main workflow."
        ]
    ),
    AppUpdateEntry(
        version: "V0.48",
        title: "History Selection Styling and iPad Detail Polish",
        releaseDate: "Older Build",
        changes: [
            "Replaced the default iPad selection highlight with a softer custom style.",
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
            "Redesigned History rows as richer cards with clearer score, device, date and status details.",
            "Added cleaner status and tag chips so saved runs are easier to scan.",
            "Made favourites, benchmark mode and thermal state easier to spot in History.",
            "Brought History rows closer to the app's newer card-based design."
        ]
    ),
    AppUpdateEntry(
        version: "V0.46",
        title: "Detailed Result View Visual Alignment",
        releaseDate: "Older Build",
        changes: [
            "Polished the detailed benchmark result view so it now visually aligns more closely with the upgraded History rows.",
            "Improved the main result summary with clearer styling and richer status chips.",
            "Changed Notes & Tags into chips so they match the rest of the app better.",
            "Made detailed result cards, reports and metrics feel more consistent."
        ]
    ),
    AppUpdateEntry(
        version: "V0.45",
        title: "Import Transparency and Better Result Messaging",
        releaseDate: "Older Build",
        changes: [
            "Updated import messages to show how many results were added and how many were already in your history.",
            "Made imports clearer when a file contains results you already have.",
            "Replaced generic success messages with more useful import summaries."
        ]
    ),
    AppUpdateEntry(
        version: "V0.44",
        title: "Shared Theme System and Visual Consistency",
        releaseDate: "Older Build",
        changes: [
            "Made Bencher's gradients, cards and accent chips more consistent across the app.",
            "Improved visual consistency across Dashboard, History, Trends, score cards and detail screens.",
            "Reduced mismatched styling so the app feels more unified."
        ]
    ),
    AppUpdateEntry(
        version: "V0.43",
        title: "Animation and Haptics Feedback Pass",
        releaseDate: "Older Build",
        changes: [
            "Added smoother score card animations as benchmark results appear.",
            "Added subtle haptics for benchmark completion, exports, imports and undo.",
            "Made important actions feel a little more responsive and polished."
        ]
    ),
    AppUpdateEntry(
        version: "V0.42",
        title: "Dashboard and Trends Presentation Polish",
        releaseDate: "Older Build",
        changes: [
            "Polished Dashboard cards and quick actions so they match the rest of Bencher better.",
            "Gave the empty Trends view a richer card instead of plain text.",
            "Made Dashboard and Trends feel more connected to the wider app design."
        ]
    ),
    AppUpdateEntry(
        version: "V0.41",
        title: "Phase 3 Polish Foundations",
        releaseDate: "Older Build",
        changes: [
            "Started a broader polish pass focused on visuals, empty states, animations and feedback.",
            "Began moving Bencher from a feature-complete build toward a more finished app.",
            "Laid the groundwork for cleaner cards, chips, gradients and interactions across the app."
        ]
    ),
    AppUpdateEntry(
        version: "V0.40",
        title: "Undo for Deletions and Favourite Terminology Cleanup",
        releaseDate: "Older Build",
        changes: [
            "Added an Undo action for the most recently deleted history item or deleted set of history items.",
            "Added a restore banner in History so recently deleted benchmark runs can be brought back quickly.",
            "Changed visible wording from pinning to favourites, while keeping older saved data compatible.",
            "Updated History indicators and swipe actions to use favourite star icons consistently."
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
            "Started a larger History upgrade focused on search, filters, favourites and safer deletion.",
            "Expanded saved history details while keeping older results readable.",
            "Made History feel less like a basic archive and more like a place to manage results properly."
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
            "Added session IDs to saved runs so benchmark history can keep better long-term context.",
            "Added a Report Card section in detailed benchmark results with performance tier, bottleneck detection and richer guidance.",
            "Polished score cards with richer gradients and cleaner backgrounds.",
            "Improved device-aware reference guidance so detailed results now present ranges more fairly based on detected device class."
        ]
    ),
    AppUpdateEntry(
        version: "V0.22",
        title: "Smarter Export Options, Faster Exporting and Cleaner History Actions",
        releaseDate: "Older Build",
        changes: [
            "Updated export so you can choose how many saved results to export, including the last 1, 5, 10, 15, 20 or all available results.",
            "Made JSON and CSV exports feel quicker by preparing them in the background.",
            "Added a visible export progress banner so the app shows when an export is being prepared.",
            "Tidied the iPad History toolbar by grouping Sort, Export, Import and Compare into one Actions menu.",
            "Fixed export reliability using a share-sheet based export flow backed by temporary files.",
            "Cleaned up CSV export generation so it does less unnecessary work.",
            "Tidied up SSD benchmark file handling."
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
            "Made benchmark history easier to move around by supporting both export formats.",
            "Added clearer messages for different device temperature levels during benchmarks."
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
