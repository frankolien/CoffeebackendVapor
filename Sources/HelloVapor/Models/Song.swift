import Fluent
import Vapor

final class Song: Model, Content, @unchecked Sendable {
    static let schema = "songs"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
    
    @Field(key: "artist")
    var artist: String
    
    @Field(key: "duration")
    var duration: Int

    init() { }

    init(id: UUID? = nil, title: String, artist: String, duration: Int) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
    }
}