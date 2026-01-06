import Fluent
import Vapor


struct SongController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let songs = routes.grouped("songs")
        songs.get(use: self.index)
        songs.post(use: self.create)
    }
    
    func index(req: Request) throws -> EventLoopFuture<[Song]> {
        return Song.query(on: req.db).all()
    }
    
    func create(req: Request) throws -> EventLoopFuture<Song> {
        let song = try req.content.decode(Song.self)
        return song.save(on: req.db).transform(to: song)
    }
}