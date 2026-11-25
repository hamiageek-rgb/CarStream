import SwiftUI
import WebKit
import AVKit
import AVFoundation
import Combine
import UniformTypeIdentifiers

@main struct CarStreamApp: App {
    var body: some Scene { WindowGroup { HomeView() } }
}

struct SavedVideo: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var url: String
}

final class Browser: NSObject, ObservableObject, WKNavigationDelegate {
    let web: WKWebView
    @Published var address = "https://m.youtube.com"
    @Published var pageTitle = "YouTube"
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var message: String? = nil

    override init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.websiteDataStore = .default()
        web = WKWebView(frame: .zero, configuration: config)
        super.init()
        web.navigationDelegate = self
        web.allowsBackForwardNavigationGestures = true
        open("https://m.youtube.com")
    }

    func open(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed
        if let url = URL(string: candidate), url.scheme == "https", let host = url.host?.lowercased(), ["youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be"].contains(host) {
            web.load(URLRequest(url: url))
        } else {
            var parts = URLComponents(string: "https://m.youtube.com/results")!
            parts.queryItems = [URLQueryItem(name: "search_query", value: trimmed)]
            if let url = parts.url { web.load(URLRequest(url: url)) }
        }
        message = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        address = webView.url?.absoluteString ?? address
        pageTitle = webView.title ?? "YouTube"
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { message = error.localizedDescription }
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { message = error.localizedDescription }
    }
}

struct BrowserView: UIViewRepresentable {
    let browser: Browser
    func makeUIView(context: Context) -> WKWebView { browser.web }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct RoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.prioritizesVideoDevices = true
        picker.tintColor = .label
        picker.activeTintColor = .systemBlue
        return picker
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

struct HomeView: View {
    @StateObject private var browser = Browser()
    @AppStorage("savedVideos") private var savedData = Data()
    @State private var saved: [SavedVideo] = []
    @State private var query = ""
    @State private var tab = 0
    @State private var importing = false
    @State private var localFiles: [URL] = []
    @State private var player: AVPlayer? = nil
    @State private var selectedFile: URL? = nil
    @State private var errorText: String? = nil
    private var folder: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Videos", isDirectory: true) }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                VStack(spacing: 8) {
                    HStack {
                        TextField("Search YouTube or paste link", text: $query)
                            .textFieldStyle(.roundedBorder).autocorrectionDisabled().textInputAutocapitalization(.never)
                            .submitLabel(.go).onSubmit { browser.open(query) }
                        Button { browser.open(query) } label: { Image(systemName: "magnifyingglass") }.accessibilityLabel("Search")
                    }.padding(.horizontal)
                    HStack(spacing: 22) {
                        Button { browser.web.goBack() } label: { Image(systemName: "chevron.left") }.disabled(!browser.canGoBack).accessibilityLabel("Back")
                        Button { browser.web.goForward() } label: { Image(systemName: "chevron.right") }.disabled(!browser.canGoForward).accessibilityLabel("Forward")
                        Button { browser.open("https://m.youtube.com") } label: { Image(systemName: "house") }.accessibilityLabel("YouTube home")
                        Button { browser.web.reload() } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Reload")
                        Spacer()
                        Button { savePage() } label: { Image(systemName: "bookmark") }.accessibilityLabel("Save link")
                    }.padding(.horizontal)
                    if let message = browser.message { Text(message).font(.caption).foregroundStyle(.secondary).padding(.horizontal) }
                    BrowserView(browser: browser)
                }
                .navigationTitle("CarStream").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { RoutePicker().frame(width: 42, height: 42).accessibilityLabel("AirPlay route picker") } }
            }.tabItem { Label("YouTube", systemImage: "play.rectangle") }.tag(0)
            NavigationStack {
                List {
                    if saved.isEmpty { Text("Save a YouTube page with the bookmark button. Links are available offline; streaming requires internet.").foregroundStyle(.secondary) }
                    ForEach(saved) { video in
                        Button { browser.open(video.url); tab = 0 } label: { VStack(alignment: .leading) { Text(video.title); Text(video.url).font(.caption).foregroundStyle(.secondary).lineLimit(1) } }
                    }.onDelete { saved.remove(atOffsets: $0); persist() }
                }.navigationTitle("Saved links")
            }.tabItem { Label("Saved", systemImage: "bookmark") }.tag(1)
            NavigationStack {
                VStack {
                    if let player = player {
                        VideoPlayer(player: player).frame(height: 220)
                        Text(selectedFile?.lastPathComponent ?? "").font(.caption)
                    }
                    List {
                        if localFiles.isEmpty { Text("Import a video you own or have permission to use. Imported files work without internet.").foregroundStyle(.secondary) }
                        ForEach(localFiles, id: \.self) { url in
                            Button { play(url) } label: { Label(url.lastPathComponent, systemImage: "film") }
                        }.onDelete { indexes in
                            for index in indexes {
                                let url = localFiles[index]
                                if selectedFile == url { player?.pause(); player = nil; selectedFile = nil }
                                do { try FileManager.default.removeItem(at: url) } catch { errorText = error.localizedDescription }
                            }
                            refreshFiles()
                        }
                    }
                }.navigationTitle("Offline videos")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button { importing = true } label: { Label("Import", systemImage: "plus") } }
                    ToolbarItem(placement: .topBarTrailing) { RoutePicker().frame(width: 42, height: 42).accessibilityLabel("AirPlay route picker") }
                }
            }.tabItem { Label("Offline", systemImage: "folder") }.tag(2)
            NavigationStack {
                List {
                    Section("Vehicle test") {
                        Text("Park before using video. Connect your iPhone to the car and look for a supported video AirPlay destination in the route picker. If none appears, this prototype cannot send video to that car.")
                        RoutePicker().frame(width: 48, height: 48)
                    }
                    Section("Prototype limits") {
                        Text("This is an iPhone application, not a CarPlay app. It does not create an icon on the vehicle display or bypass parked-state restrictions.")
                        Text("YouTube requires internet. Web playback, login and AirPlay depend on YouTube, iOS and the receiving device. The app does not download YouTube videos.")
                    }
                }.navigationTitle("Compatibility")
            }.tabItem { Label("Test", systemImage: "car") }.tag(3)
        }
        .tint(Color(red: 0.19, green: 0.45, blue: 0.75))
        .onAppear { saved = (try? JSONDecoder().decode([SavedVideo].self, from: savedData)) ?? []; refreshFiles() }
        .onChange(of: tab) { _, value in if value != 2 { player?.pause() } }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.movie], allowsMultipleSelection: false) { result in
            do { if let url = try result.get().first { try importFile(url) } } catch { errorText = error.localizedDescription }
        }
        .alert("CarStream", isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) { Button("OK", role: .cancel) {} } message: { Text(errorText ?? "") }
    }

    private func savePage() {
        guard let url = browser.web.url?.absoluteString else { return }
        guard !saved.contains(where: { $0.url == url }) else { errorText = "Already saved."; return }
        saved.insert(SavedVideo(title: browser.pageTitle, url: url), at: 0); persist()
        errorText = "Link saved."
    }
    private func persist() { if let data = try? JSONEncoder().encode(saved) { savedData = data } }
    private func refreshFiles() {
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            localFiles = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).sorted { $0.lastPathComponent < $1.lastPathComponent }
        } catch { errorText = error.localizedDescription }
    }
    private func importFile(_ url: URL) throws {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        let dest = folder.appendingPathComponent(url.lastPathComponent)
        guard !FileManager.default.fileExists(atPath: dest.path) else { errorText = "A file with this name already exists."; return }
        try FileManager.default.copyItem(at: url, to: dest)
        refreshFiles()
    }
    private func play(_ url: URL) {
        player?.pause()
        do { try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback); try AVAudioSession.sharedInstance().setActive(true) } catch { errorText = error.localizedDescription }
        let next = AVPlayer(url: url)
        next.allowsExternalPlayback = true
        selectedFile = url; player = next; next.play()
    }
}
