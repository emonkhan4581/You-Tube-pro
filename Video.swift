import Foundation

struct Video: Identifiable, Decodable {
    let id: String
    let title: String
    let channelTitle: String
    let thumbnailURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case snippet
    }

    enum SnippetKeys: String, CodingKey {
        case title, channelTitle, thumbnails
    }

    enum ThumbnailKeys: String, CodingKey {
        case medium, high, defaultThumbnail = "default"
    }

    enum ThumbnailValueKeys: String, CodingKey {
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idContainer = try container.nestedContainer(keyedBy: IDKeys.self, forKey: .id)
        id = try idContainer.decode(String.self, forKey: .videoId)

        let snippet = try container.nestedContainer(keyedBy: SnippetKeys.self, forKey: .snippet)
        title = try snippet.decode(String.self, forKey: .title)
        channelTitle = try snippet.decode(String.self, forKey: .channelTitle)

        let thumbs = try snippet.nestedContainer(keyedBy: ThumbnailKeys.self, forKey: .thumbnails)
        let thumb = (try? thumbs.nestedContainer(keyedBy: ThumbnailValueKeys.self, forKey: .high))
            ?? (try? thumbs.nestedContainer(keyedBy: ThumbnailValueKeys.self, forKey: .medium))
            ?? (try? thumbs.nestedContainer(keyedBy: ThumbnailValueKeys.self, forKey: .defaultThumbnail))
        let rawURL = try? thumb?.decode(String.self, forKey: .url)
        thumbnailURL = rawURL.flatMap(URL.init(string:))
    }

    private enum IDKeys: String, CodingKey {
        case videoId
    }
}

private struct SearchResponse: Decodable {
    let items: [Video]
}

enum YouTubeAPIError: LocalizedError {
    case missingKey
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingKey: return "আগে Config.swift ফাইলে YouTube API key যোগ করুন।"
        case .invalidResponse: return "YouTube থেকে সঠিক উত্তর পাওয়া যায়নি। পরে আবার চেষ্টা করুন।"
        }
    }
}

final class YouTubeAPI {
    func search(_ query: String) async throws -> [Video] {
        guard AppConfig.youtubeAPIKey != "YOUR_YOUTUBE_DATA_API_KEY",
              !AppConfig.youtubeAPIKey.isEmpty else {
            throw YouTubeAPIError.missingKey
        }

        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "25"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: AppConfig.youtubeAPIKey)
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw YouTubeAPIError.invalidResponse
        }
        return try JSONDecoder().decode(SearchResponse.self, from: data).items
    }
}
