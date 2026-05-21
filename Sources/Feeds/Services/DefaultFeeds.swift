// DefaultFeeds.swift — Default feed subscriptions seeded on first launch.
//
// C#: Like a static class with seed data — replaces the old bundled feeds.json.
// These are inserted into SQLite on first run; users can add/remove feeds afterward.

import Foundation

/// Default feed subscriptions to seed on first launch.
/// C#: internal static class DefaultFeeds { public static List<FeedRecord> All => ... }
enum DefaultFeeds {

    /// All default feed records, ordered by sortOrder.
    /// HBX has suppressHeroImage = true because its RSS content already embeds full images.
    static let all: [FeedRecord] = [
        // --- Standalone feeds ---
        FeedRecord(id: 0, title: "HBX", url: "https://feeds.feedburner.com/hypebeast/feed/",
                   groupId: nil, groupTitle: nil, sortOrder: 0, suppressHeroImage: true),
        FeedRecord(id: 0, title: "WIRED", url: "https://www.wired.com/feed/rss",
                   groupId: nil, groupTitle: nil, sortOrder: 1, suppressHeroImage: false),
        FeedRecord(id: 0, title: "MyBroadband", url: "https://mybroadband.co.za/news/feed",
                   groupId: nil, groupTitle: nil, sortOrder: 2, suppressHeroImage: false),

        // --- Sports ---
        FeedRecord(id: 0, title: "ESPN - RPM", url: "https://www.espn.com/espn/rss/rpm/news/",
                   groupId: "3", groupTitle: "Sports", sortOrder: 100, suppressHeroImage: false),
        FeedRecord(id: 0, title: "News24 Sport - Soccer", url: "https://feeds.capi24.com/v1/Search/articles/sport/soccer/rss",
                   groupId: "3", groupTitle: "Sports", sortOrder: 101, suppressHeroImage: false),
        FeedRecord(id: 0, title: "WRC", url: "https://www.wrc.com/templates/generated/1/raw/en.xml",
                   groupId: "3", groupTitle: "Sports", sortOrder: 102, suppressHeroImage: false),
        FeedRecord(id: 0, title: "CARMAG", url: "https://www.carmag.co.za/news/feed/",
                   groupId: "3", groupTitle: "Sports", sortOrder: 103, suppressHeroImage: false),
        FeedRecord(id: 0, title: "TopAuto", url: "https://topauto.co.za/news/feed/",
                   groupId: "3", groupTitle: "Sports", sortOrder: 104, suppressHeroImage: false),
        FeedRecord(id: 0, title: "UFC News", url: "https://www.ufc.com/rss/news/",
                   groupId: "3", groupTitle: "Sports", sortOrder: 105, suppressHeroImage: false),

        // --- News ---
        FeedRecord(id: 0, title: "GQ", url: "https://rss.iol.io/gq/all-content-feed",
                   groupId: "4", groupTitle: "News", sortOrder: 200, suppressHeroImage: false),
        FeedRecord(id: 0, title: "9ice Entertainment", url: "https://9iceentertainment.com/category/news/feed/",
                   groupId: "4", groupTitle: "News", sortOrder: 201, suppressHeroImage: false),
        FeedRecord(id: 0, title: "FRESHMENMAG", url: "https://freshmenmag.co.za/feed/",
                   groupId: "4", groupTitle: "News", sortOrder: 202, suppressHeroImage: false),
        FeedRecord(id: 0, title: "CultureCollecter", url: "https://culturecollecter.co.za/feed/",
                   groupId: "4", groupTitle: "News", sortOrder: 203, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Kreative Kornerr", url: "https://kreativekornerr.co.za/feed/",
                   groupId: "4", groupTitle: "News", sortOrder: 204, suppressHeroImage: false),
        FeedRecord(id: 0, title: "News24", url: "https://feeds.24.com/articles/news24/TopStories/rss",
                   groupId: "4", groupTitle: "News", sortOrder: 205, suppressHeroImage: false),
        FeedRecord(id: 0, title: "SABC News - South Africa", url: "https://www.sabcnews.com/sabcnews/category/south-africa/feed/",
                   groupId: "4", groupTitle: "News", sortOrder: 206, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Daily Maverick", url: "https://www.dailymaverick.co.za/dmrss",
                   groupId: "4", groupTitle: "News", sortOrder: 207, suppressHeroImage: false),
        FeedRecord(id: 0, title: "BusinessTech", url: "https://businesstech.co.za/news/rss",
                   groupId: "4", groupTitle: "News", sortOrder: 208, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Daily Investor", url: "https://dailyinvestor.com/feed/",
                   groupId: "4", groupTitle: "News", sortOrder: 209, suppressHeroImage: false),
        FeedRecord(id: 0, title: "MDN News", url: "https://mdntvlive.com/category/mdn-news/feed/",
                   groupId: "4", groupTitle: "News", sortOrder: 210, suppressHeroImage: false),

        // --- Tech ---
        FeedRecord(id: 0, title: "TechCrunch", url: "https://techcrunch.com/feed/",
                   groupId: "5", groupTitle: "Tech", sortOrder: 300, suppressHeroImage: false),
        FeedRecord(id: 0, title: "The Hackers News", url: "https://feeds.feedburner.com/TheHackersNews",
                   groupId: "5", groupTitle: "Tech", sortOrder: 301, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Microsoft Developer Blogs", url: "https://devblogs.microsoft.com/landingpage/",
                   groupId: "5", groupTitle: "Tech", sortOrder: 302, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Stack Overflow", url: "https://stackoverflow.blog/feed",
                   groupId: "5", groupTitle: "Tech", sortOrder: 303, suppressHeroImage: false),
        FeedRecord(id: 0, title: "DEV Community", url: "https://dev.to/feed",
                   groupId: "5", groupTitle: "Tech", sortOrder: 304, suppressHeroImage: false),
        FeedRecord(id: 0, title: "CodeProject Latest Articles", url: "https://www.codeproject.com/WebServices/ArticleRSS.aspx",
                   groupId: "5", groupTitle: "Tech", sortOrder: 305, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Google Developers Blog", url: "https://developers.googleblog.com/feeds/posts/default/",
                   groupId: "5", groupTitle: "Tech", sortOrder: 306, suppressHeroImage: false),
        FeedRecord(id: 0, title: "C-Sharpcorner Latest Content", url: "https://www.c-sharpcorner.com/rss/latestcontentall.aspx",
                   groupId: "5", groupTitle: "Tech", sortOrder: 307, suppressHeroImage: false),
        FeedRecord(id: 0, title: "C-Sharpcorner Latest News", url: "https://www.c-sharpcorner.com/rss/news.aspx",
                   groupId: "5", groupTitle: "Tech", sortOrder: 308, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Syncfusion C-Sharp", url: "https://www.syncfusion.com/blogs/category/c-sharp/feed",
                   groupId: "5", groupTitle: "Tech", sortOrder: 309, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Sitepoint", url: "https://sitepoint.com/sitepoint.rss",
                   groupId: "5", groupTitle: "Tech", sortOrder: 310, suppressHeroImage: false),
        FeedRecord(id: 0, title: "freeCodeCamp.org", url: "https://www.freecodecamp.org/news/rss/",
                   groupId: "5", groupTitle: "Tech", sortOrder: 311, suppressHeroImage: false),
        FeedRecord(id: 0, title: "StationX - Cyber Security Blog", url: "https://www.stationx.net/blog/feed/",
                   groupId: "5", groupTitle: "Tech", sortOrder: 312, suppressHeroImage: false),
        FeedRecord(id: 0, title: "ByteByteGo Newsletter", url: "https://blog.bytebytego.com/feed",
                   groupId: "5", groupTitle: "Tech", sortOrder: 313, suppressHeroImage: false),

        // --- Runtastic ---
        FeedRecord(id: 0, title: "Cardio", url: "https://www.runtastic.com/blog/en/category/cardio/feed/",
                   groupId: "6", groupTitle: "Runtastic", sortOrder: 400, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Strength", url: "https://www.runtastic.com/blog/en/category/strength/feed/",
                   groupId: "6", groupTitle: "Runtastic", sortOrder: 401, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Nutrition", url: "https://www.runtastic.com/blog/en/category/nutrition/feed/",
                   groupId: "6", groupTitle: "Runtastic", sortOrder: 402, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Daily-Habits", url: "https://www.runtastic.com/blog/en/category/daily-habits/feed/",
                   groupId: "6", groupTitle: "Runtastic", sortOrder: 403, suppressHeroImage: false),

        // --- Reddit ---
        FeedRecord(id: 0, title: "C#", url: "https://www.reddit.com/r/csharp.rss",
                   groupId: "7", groupTitle: "Reddit", sortOrder: 500, suppressHeroImage: false),
        FeedRecord(id: 0, title: "UFC", url: "https://www.reddit.com/r/ufc.rss",
                   groupId: "7", groupTitle: "Reddit", sortOrder: 501, suppressHeroImage: false),
        FeedRecord(id: 0, title: ".NET", url: "https://www.reddit.com/r/dotnet.rss",
                   groupId: "7", groupTitle: "Reddit", sortOrder: 502, suppressHeroImage: false),
        FeedRecord(id: 0, title: "South Africa", url: "https://www.reddit.com/r/southafrica.rss",
                   groupId: "7", groupTitle: "Reddit", sortOrder: 503, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Programmer Humor", url: "https://www.reddit.com/r/ProgrammerHumor.rss",
                   groupId: "7", groupTitle: "Reddit", sortOrder: 504, suppressHeroImage: false),
        FeedRecord(id: 0, title: "Sportscar Racing", url: "https://www.reddit.com/r/Sportscar_Racing.rss",
                   groupId: "7", groupTitle: "Reddit", sortOrder: 505, suppressHeroImage: false),
        FeedRecord(id: 0, title: "D365 Finance Operations", url: "https://www.reddit.com/r/D365FinanceOperations.rss",
                   groupId: "7", groupTitle: "Reddit", sortOrder: 506, suppressHeroImage: false),
    ]
}
