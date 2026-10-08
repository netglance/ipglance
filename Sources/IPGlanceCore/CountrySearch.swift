import Foundation

/// Filter for the kill switch country picker.
public enum CountrySearch {
    /// Empty query keeps the input. Otherwise: name contains the query (case/diacritic-insensitive)
    /// or code starts with it; an exact code match goes first, the rest keeps input order.
    public static func filter(_ countries: [(code: String, name: String)], query: String) -> [(code: String, name: String)] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return countries }
        let hits = countries.filter { $0.name.localizedStandardContains(q) || $0.code.lowercased().hasPrefix(q.lowercased()) }
        let exact = hits.filter { $0.code.caseInsensitiveCompare(q) == .orderedSame }
        return exact + hits.filter { $0.code.caseInsensitiveCompare(q) != .orderedSame }
    }
}
