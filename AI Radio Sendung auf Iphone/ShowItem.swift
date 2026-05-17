import Foundation

struct ShowItem: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let coverImageName: String
    let folderName: String
    let playlistFileName: String
    let audioFileName: String?
    let durationHint: TimeInterval?
    let description: String?
}

extension ShowItem {
    // Add new shows here. Audio is resolved from Documents/10_AI_Radio_Exports/<folderName>/00_Playlist.m3u.
    static let examples: [ShowItem] = [
        ShowItem(
            id: "balkan-disco",
            title: "Balkan Disco",
            subtitle: "Brass, bass, neon",
            coverImageName: "cover_balkan_disco",
            folderName: "14-a - Balkan Disco",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "A vivid Balkan dance radio run."
        ),
        ShowItem(
            id: "blues-at-five",
            title: "Blues at Five",
            subtitle: "Late light blues",
            coverImageName: "cover_blues",
            folderName: "09-a - Blues at five",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "Grit, warmth, and slow-burning guitar."
        ),
        ShowItem(
            id: "velvet-after-midnight",
            title: "Velvet After Midnight",
            subtitle: "R&B night flow",
            coverImageName: "cover_rb",
            folderName: "15-a - R&B Velvet after midnight",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "Smooth midnight R&B with cinematic breaks."
        ),
        ShowItem(
            id: "baroque-hour",
            title: "Baroque Hour",
            subtitle: "Sacred drama",
            coverImageName: "cover_sacred",
            folderName: "10-a - Barock - Licht, Leid und Erlösung - Sakrale Musik",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "Sacred baroque textures and choral depth."
        ),
        ShowItem(
            id: "soul-session",
            title: "Soul Session",
            subtitle: "Morning glow",
            coverImageName: "cover_soul",
            folderName: "06-a - Morning Soul",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "Warm grooves and bright vocal colors."
        ),
        ShowItem(
            id: "electronic-night",
            title: "Electronic Night",
            subtitle: "Deep signals",
            coverImageName: "cover_electro",
            folderName: "04-a - Electronic Depths",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "Synthetic depth, pulse, and atmosphere."
        ),
        ShowItem(
            id: "heavy-metal-special",
            title: "Heavy Metal Special",
            subtitle: "Pure metal",
            coverImageName: "cover_metal",
            folderName: "02-a - Pure Metal",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "High-energy riffs and dramatic metal worlds."
        ),
        ShowItem(
            id: "tambura-journey",
            title: "Tambura Journey",
            subtitle: "World folk routes",
            coverImageName: "cover_world",
            folderName: "01-b - Weltklang",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "A placeholder-style world music route using the Weltklang folder."
        ),
        ShowItem(
            id: "jazz-blue-structures",
            title: "Blue Structures",
            subtitle: "Night jazz",
            coverImageName: "cover_jazz",
            folderName: "08-a - Jazz - Blue Structures",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "Modern jazz fragments, city light, and room tone."
        ),
        ShowItem(
            id: "open-road-country",
            title: "Open Road Country",
            subtitle: "Wide road stories",
            coverImageName: "cover_country",
            folderName: "03-a - Open Road Country",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "Country scenes built for long drives."
        ),
        ShowItem(
            id: "northern-skies",
            title: "Northern Skies",
            subtitle: "Indie currents",
            coverImageName: "cover_indie",
            folderName: "05-a - Indie - Northern Skies",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "Soft indie contrasts and bright edges."
        ),
        ShowItem(
            id: "grace-omalley",
            title: "Grace O'Malley",
            subtitle: "Irish folk saga",
            coverImageName: "cover_irish",
            folderName: "07-a - Irish Folk - Grace O’Malley – The Sea and the Crown",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "A sea-bound Irish folk narrative."
        ),
        ShowItem(
            id: "kingston-skies",
            title: "Kingston Skies",
            subtitle: "Reggae sunlight",
            coverImageName: "cover_reggae",
            folderName: "11-a - Reggae - Kingston Skies",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "Reggae warmth and bright city motion."
        ),
        ShowItem(
            id: "golden-days",
            title: "Golden Days",
            subtitle: "70s neon nights",
            coverImageName: "cover_70s",
            folderName: "12-a - 70's-Golden Days, Neon Nights",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "Retro light, disco pop, and big choruses."
        ),
        ShowItem(
            id: "no-peace-signal",
            title: "No Peace in the Signal",
            subtitle: "Rap report",
            coverImageName: "cover_rap",
            folderName: "13-a - Rap-No Peace in the Signal",
            playlistFileName: "00_Playlist.m3u",
            audioFileName: nil,
            durationHint: nil,
            description: "Sharp rap vignettes with a newswire pulse."
        )
    ]
}
