import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("showFloatingLyrics") private var showFloatingLyrics = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showDockIcon") private var showDockIcon = false
    
    @AppStorage("floatingOpacity") private var floatingOpacity = 1.0
    @AppStorage("floatingFontSize") private var floatingFontSize = 36.0
    
    @AppStorage("audioQuality") private var audioQuality = "bestaudio"
    @AppStorage("defaultVolume") private var defaultVolume = 1.0
    
    @AppStorage("maxCacheSizeGB") private var maxCacheSizeGB = 2.0
    
    @State private var cacheSize: String = "Calculating..."
    
    var body: some View {
        TabView {
            // General Tab
            Form {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        if #available(macOS 13.0, *) {
                            if newValue {
                                try? SMAppService.mainApp.register()
                            } else {
                                try? SMAppService.mainApp.unregister()
                            }
                        }
                    }
                
                Toggle("Show Dock Icon (requires app restart)", isOn: $showDockIcon)
                    .onChange(of: showDockIcon) { newValue in
                        let alert = NSAlert()
                        alert.messageText = "Restart Required"
                        alert.informativeText = "Please restart Audio CLI for the Dock Icon setting to take effect."
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                
                Toggle("Show Floating Lyrics Window", isOn: $showFloatingLyrics)
                    .onChange(of: showFloatingLyrics) { newValue in
                        NotificationCenter.default.post(name: NSNotification.Name("ToggleFloatingLyrics"), object: newValue)
                    }
            }
            .padding(20)
            .tabItem { Label("General", systemImage: "gear") }
            
            // Appearance Tab
            Form {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading) {
                        Text("Floating Lyrics Opacity: \(Int(floatingOpacity * 100))%")
                        Slider(value: $floatingOpacity, in: 0.1...1.0, step: 0.05)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Floating Lyrics Font Size: \(Int(floatingFontSize))")
                        Picker("", selection: $floatingFontSize) {
                            Text("Small").tag(24.0)
                            Text("Medium").tag(36.0)
                            Text("Large").tag(48.0)
                            Text("Extra Large").tag(64.0)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .padding(20)
            .tabItem { Label("Appearance", systemImage: "paintpalette") }
            
            // Playback Tab
            Form {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading) {
                        Text("Audio Quality (yt-dlp)")
                        Picker("", selection: $audioQuality) {
                            Text("Best Audio").tag("bestaudio")
                            Text("256 kbps").tag("256k")
                            Text("128 kbps (Data Saver)").tag("128k")
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Default Startup Volume: \(Int(defaultVolume * 100))%")
                        Slider(value: $defaultVolume, in: 0.0...1.0, step: 0.05)
                    }
                }
            }
            .padding(20)
            .tabItem { Label("Playback", systemImage: "play.circle") }
            
            // Storage Tab
            Form {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Current Audio Cache:")
                        Spacer()
                        Text(cacheSize)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Max Auto-Cleanup Size: \(String(format: "%.1f", maxCacheSizeGB)) GB")
                        Slider(value: $maxCacheSizeGB, in: 0.5...10.0, step: 0.5)
                        Text("When the cache exceeds this limit, older songs will be automatically deleted.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear Cache Now") {
                        clearCache()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding(20)
            .tabItem { Label("Storage", systemImage: "externaldrive") }
            .onAppear(perform: calculateCacheSize)
        }
        .padding()
        .frame(width: 480, height: 320)
    }
    
    private func calculateCacheSize() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("audio-cli-yt")
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) else {
            cacheSize = "0 MB"
            return
        }
        
        var totalSize: Int64 = 0
        for file in files {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: file.path),
               let size = attrs[.size] as? Int64 {
                totalSize += size
            }
        }
        
        let mb = Double(totalSize) / (1024 * 1024)
        cacheSize = String(format: "%.1f MB", mb)
    }
    
    private func clearCache() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("audio-cli-yt")
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        calculateCacheSize()
    }
}
