import SwiftUI

struct ContentView: View {
    @State private var query = ""
    @State private var videos: [Video] = []
    @State private var selectedVideo: Video?
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let api = YouTubeAPI()

    private let background = Color(red: 0.055, green: 0.055, blue: 0.065)
    private let accent = Color(red: 0.95, green: 0.08, blue: 0.12)

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundStyle(accent)
                            .font(.system(size: 30, weight: .bold))
                        Text("YouTube Pro")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.top, 8)

                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("ভিডিও খুঁজুন…", text: $query)
                            .foregroundStyle(.white)
                            .submitLabel(.search)
                            .onSubmit { Task { await search() } }
                        if !query.isEmpty {
                            Button { query = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                        }
                        Button { Task { await search() } } label: {
                            Text("সার্চ").bold()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(accent, in: Capsule())
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.08)))

                    if isLoading {
                        ProgressView("খোঁজা হচ্ছে…").tint(accent).foregroundStyle(.white)
                        Spacer()
                    } else if let errorMessage {
                        ContentUnavailableView("সার্চ করা যাচ্ছে না", systemImage: "wifi.exclamationmark",
                                               description: Text(errorMessage).foregroundStyle(.secondary))
                            .foregroundStyle(.white)
                        Spacer()
                    } else if videos.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "play.rectangle.on.rectangle")
                                .font(.system(size: 48)).foregroundStyle(accent)
                            Text("আপনার পছন্দের ভিডিও খুঁজুন")
                                .font(.headline).foregroundStyle(.white)
                            Text("YouTube-এর পাবলিক ভিডিও সার্চ করতে উপরে লিখুন।")
                                .font(.subheadline).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(videos) { video in
                            Button { selectedVideo = video } label: {
                                HStack(spacing: 12) {
                                    AsyncImage(url: video.thumbnailURL) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Rectangle().fill(Color.white.opacity(0.1))
                                            .overlay(Image(systemName: "play.fill").foregroundStyle(accent))
                                    }
                                    .frame(width: 128, height: 76)
                                    .clipShape(RoundedRectangle(cornerRadius: 9))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(video.title).font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white).lineLimit(2)
                                        Text(video.channelTitle).font(.caption)
                                            .foregroundStyle(.gray).lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 5)
                                .listRowBackground(background)
                            }
                            .buttonStyle(.plain)
                            .listRowSeparatorTint(.white.opacity(0.12))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                .padding(.horizontal, 16)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedVideo) { video in
                NavigationStack {
                    VStack(spacing: 16) {
                        YouTubePlayerView(videoID: video.id)
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .background(.black)
                        Text(video.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        Text(video.channelTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .background(background.ignoresSafeArea())
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("বন্ধ") { selectedVideo = nil }.tint(accent)
                        }
                    }
                }
                .preferredColorScheme(.dark)
            }
        }
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            videos = try await api.search(term)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
