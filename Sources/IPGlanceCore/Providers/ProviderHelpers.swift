import Foundation

func validateHTTP(_ response: URLResponse) throws {
    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
        throw URLError(.badServerResponse)
    }
}

/// "AS15169 Google LLC" → ("AS15169", "Google LLC")
func parseOrg(_ org: String?) -> (asn: String, isp: String) {
    let trimmed = (org ?? "").trimmingCharacters(in: .whitespaces)
    guard let spaceIdx = trimmed.firstIndex(of: " ") else { return (trimmed, trimmed) }
    return (
        String(trimmed[trimmed.startIndex..<spaceIdx]),
        String(trimmed[trimmed.index(after: spaceIdx)...])
    )
}
