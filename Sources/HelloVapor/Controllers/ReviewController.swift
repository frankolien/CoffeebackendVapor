import Fluent
import Vapor
import Foundation

struct ReviewController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let reviews = routes.grouped("reviews")
        
        reviews.get(use: self.index)
        reviews.get(":reviewID", use: self.show)
        reviews.get("coffee-type", ":coffeeTypeID", use: self.getByCoffeeType)
        reviews.get("location", ":locationID", use: self.getByLocation)
        reviews.get("coffee-type", ":coffeeTypeID", "summary", use: self.getCoffeeTypeSummary)
        reviews.get("location", ":locationID", "summary", use: self.getLocationSummary)
        
        let protected = reviews.grouped(JWTAuthenticator())
        protected.post(use: self.create)
        protected.put(":reviewID", use: self.update)
        protected.delete(":reviewID", use: self.delete)
    }
    
    func index(req: Request) async throws -> [ReviewResponseDTO] {
        let reviews = try await Review.query(on: req.db)
            .with(\.$user)
            .with(\.$coffeeType)
            .with(\.$location)
            .all()
        
        var result: [ReviewResponseDTO] = []
        for review in reviews {
            let user = try await review.$user.get(on: req.db)
            let coffeeType = try? await review.$coffeeType.get(on: req.db)
            let location = try? await review.$location.get(on: req.db)
            result.append(ReviewResponseDTO(from: review, user: user, coffeeType: coffeeType, location: location))
        }
        return result
    }
    
    func show(req: Request) async throws -> ReviewResponseDTO {
        guard let review = try await Review.find(req.parameters.get("reviewID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let user = try await review.$user.get(on: req.db)
        let coffeeType = try? await review.$coffeeType.get(on: req.db)
        let location = try? await review.$location.get(on: req.db)
        
        return ReviewResponseDTO(from: review, user: user, coffeeType: coffeeType, location: location)
    }
    
    func getByCoffeeType(req: Request) async throws -> [ReviewResponseDTO] {
        guard let coffeeTypeID = req.parameters.get("coffeeTypeID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let reviews = try await Review.query(on: req.db)
            .filter(\.$coffeeType.$id == coffeeTypeID)
            .with(\.$user)
            .with(\.$coffeeType)
            .sort(\.$createdAt, .descending)
            .all()
        
        var result: [ReviewResponseDTO] = []
        for review in reviews {
            let user = try await review.$user.get(on: req.db)
            let coffeeType = try await review.$coffeeType.get(on: req.db)
            result.append(ReviewResponseDTO(from: review, user: user, coffeeType: coffeeType, location: nil))
        }
        return result
    }
    
    func getByLocation(req: Request) async throws -> [ReviewResponseDTO] {
        guard let locationID = req.parameters.get("locationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let reviews = try await Review.query(on: req.db)
            .filter(\.$location.$id == locationID)
            .with(\.$user)
            .with(\.$location)
            .sort(\.$createdAt, .descending)
            .all()
        
        var result: [ReviewResponseDTO] = []
        for review in reviews {
            let user = try await review.$user.get(on: req.db)
            let location = try await review.$location.get(on: req.db)
            result.append(ReviewResponseDTO(from: review, user: user, coffeeType: nil, location: location))
        }
        return result
    }
    
    func getCoffeeTypeSummary(req: Request) async throws -> RatingSummaryDTO {
        guard let coffeeTypeID = req.parameters.get("coffeeTypeID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let reviews = try await Review.query(on: req.db)
            .filter(\.$coffeeType.$id == coffeeTypeID)
            .all()
        
        guard !reviews.isEmpty else {
            return RatingSummaryDTO(averageRating: 0, totalReviews: 0, ratingDistribution: [:])
        }
        
        let totalRating = reviews.reduce(0) { $0 + $1.rating }
        let averageRating = Double(totalRating) / Double(reviews.count)
        
        var distribution: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for review in reviews {
            distribution[review.rating, default: 0] += 1
        }
        
        return RatingSummaryDTO(
            averageRating: round(averageRating * 10) / 10,
            totalReviews: reviews.count,
            ratingDistribution: distribution
        )
    }
    
    func getLocationSummary(req: Request) async throws -> RatingSummaryDTO {
        guard let locationID = req.parameters.get("locationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let reviews = try await Review.query(on: req.db)
            .filter(\.$location.$id == locationID)
            .all()
        
        guard !reviews.isEmpty else {
            return RatingSummaryDTO(averageRating: 0, totalReviews: 0, ratingDistribution: [:])
        }
        
        let totalRating = reviews.reduce(0) { $0 + $1.rating }
        let averageRating = Double(totalRating) / Double(reviews.count)
        
        var distribution: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for review in reviews {
            distribution[review.rating, default: 0] += 1
        }
        
        return RatingSummaryDTO(
            averageRating: round(averageRating * 10) / 10,
            totalReviews: reviews.count,
            ratingDistribution: distribution
        )
    }
    
    func create(req: Request) async throws -> ReviewResponseDTO {
        let user = try req.auth.require(User.self)
        
        try ReviewCreateDTO.validate(content: req)
        let reviewDTO = try req.content.decode(ReviewCreateDTO.self)
        
        guard let rating = reviewDTO.rating, rating >= 1 && rating <= 5 else {
            throw Abort(.badRequest, reason: "Rating must be between 1 and 5")
        }
        
        guard reviewDTO.coffeeTypeID != nil || reviewDTO.locationID != nil else {
            throw Abort(.badRequest, reason: "Either coffeeTypeID or locationID must be provided")
        }
        
        let review = Review(
            userID: user.id!,
            coffeeTypeID: reviewDTO.coffeeTypeID,
            locationID: reviewDTO.locationID,
            rating: rating,
            comment: reviewDTO.comment
        )
        
        try await review.save(on: req.db)
        
        let coffeeType = try? await review.$coffeeType.get(on: req.db)
        let location = try? await review.$location.get(on: req.db)
        
        return ReviewResponseDTO(from: review, user: user, coffeeType: coffeeType, location: location)
    }
    
    func update(req: Request) async throws -> ReviewResponseDTO {
        let user = try req.auth.require(User.self)
        
        guard let review = try await Review.find(req.parameters.get("reviewID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        if review.$user.id != user.id {
            throw Abort(.forbidden)
        }
        
        let reviewDTO = try req.content.decode(ReviewCreateDTO.self)
        
        if let rating = reviewDTO.rating {
            guard rating >= 1 && rating <= 5 else {
                throw Abort(.badRequest, reason: "Rating must be between 1 and 5")
            }
            review.rating = rating
        }
        
        if let comment = reviewDTO.comment {
            review.comment = comment
        }
        
        try await review.save(on: req.db)
        
        let coffeeType = try? await review.$coffeeType.get(on: req.db)
        let location = try? await review.$location.get(on: req.db)
        
        return ReviewResponseDTO(from: review, user: user, coffeeType: coffeeType, location: location)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let review = try await Review.find(req.parameters.get("reviewID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        if review.$user.id != user.id {
            throw Abort(.forbidden)
        }
        
        try await review.delete(on: req.db)
        return .noContent
    }
}

