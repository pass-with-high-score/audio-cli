import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("showFloatingLyrics") private var showFloatingLyrics = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
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
                
                Toggle("Show Floating Lyrics Window", isOn: $showFloatingLyrics)
                    .onChange(of: showFloatingLyrics) { newValue in
                        NotificationCenter.default.post(name: NSNotification.Name("ToggleFloatingLyrics"), object: newValue)
                    }
            }
            .padding(20)
            .frame(width: 400, height: 150)
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            // Storage Tab
            Form {
                HStack {
                    Text("Audio Cache:")
                    Spacer()
                    Text(cacheSize)
                        .foregroundColor(.secondary)
                }
                
                Button("Clear Cache") {
                    clearCache()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(20)
            .frame(width: 400, height: 150)
            .tabItem {
                Label("Storage", systemImage: "externaldrive")
            }
            .onAppear(perform: calculateCacheSize)
        }
        .padding()
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
