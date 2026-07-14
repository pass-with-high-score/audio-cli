import Foundation

func run() async {
    let query = "https://youtu.be/heMYSOZoT3c?si=fDbswjBI8ISSHX9F"
    let effectiveQuery = query.lowercased().hasPrefix("http") ? query : "ytsearch1:\(query)"
    
    let binaryPath = "/Users/nqmgaming/Library/Application Support/audio-cli/yt-dlp"
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: binaryPath)
    process.arguments = [
        "--extractor-args", "youtube:player_client=android",
        "--print", "%(title)s|%(id)s|%(webpage_url)s|%(uploader)s",
        effectiveQuery
    ]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    do {
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print("OUTPUT:", output)
            let line = output.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = line.components(separatedBy: "|")
            print("PARTS:", parts)
        }
    } catch {
        print("ERROR:", error)
    }
}

Task {
    await run()
    exit(0)
}
RunLoop.main.run()
