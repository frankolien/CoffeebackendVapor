import Fluent
import Vapor
import Foundation

struct OrderController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let orders = routes.grouped("orders")
            .grouped(JWTAuthenticator())
        
        orders.get(use: self.index)
        orders.get(":orderID", use: self.show)
        orders.post(use: self.create)
        orders.put(":orderID", use: self.update)
        orders.delete(":orderID", use: self.delete)
        orders.get("my-orders", use: self.myOrders)
    }
    
    func index(req: Request) async throws -> [OrderResponseDTO] {
        let user = try req.auth.require(User.self)
        
        var query = Order.query(on: req.db)
            .with(\.$coffeeType)
            .with(\.$location)
        
        if !user.isAdmin {
            query = query.filter(\.$user.$id == user.id!)
        }
        
        let orders = try await query.all()
        
        var result: [OrderResponseDTO] = []
        for order in orders {
            let coffeeType = try await order.$coffeeType.get(on: req.db)
            let location = try await order.$location.get(on: req.db)
            result.append(OrderResponseDTO(from: order, coffeeType: coffeeType, location: location))
        }
        return result
    }
    
    func myOrders(req: Request) async throws -> [OrderResponseDTO] {
        let user = try req.auth.require(User.self)
        
        let orders = try await Order.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .with(\.$coffeeType)
            .with(\.$location)
            .sort(\.$createdAt, .descending)
            .all()
        
        var result: [OrderResponseDTO] = []
        for order in orders {
            let coffeeType = try await order.$coffeeType.get(on: req.db)
            let location = try await order.$location.get(on: req.db)
            result.append(OrderResponseDTO(from: order, coffeeType: coffeeType, location: location))
        }
        return result
    }
    
    func show(req: Request) async throws -> OrderResponseDTO {
        let user = try req.auth.require(User.self)
        
        guard let order = try await Order.find(req.parameters.get("orderID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        if !user.isAdmin && order.$user.id != user.id {
            throw Abort(.forbidden)
        }
        
        let coffeeType = try await order.$coffeeType.get(on: req.db)
        let location = try await order.$location.get(on: req.db)
        
        return OrderResponseDTO(from: order, coffeeType: coffeeType, location: location)
    }
    
    func create(req: Request) async throws -> OrderResponseDTO {
        let user = try req.auth.require(User.self)
        
        let orderDTO = try req.content.decode(OrderCreateDTO.self)
        
        guard let coffeeType = try await CoffeeType.find(orderDTO.coffeeTypeID, on: req.db) else {
            throw Abort(.notFound, reason: "Coffee type not found")
        }
        
        guard coffeeType.isAvailable else {
            throw Abort(.badRequest, reason: "Coffee type is not available")
        }
        
        guard let location = try await Location.find(orderDTO.locationID, on: req.db) else {
            throw Abort(.notFound, reason: "Location not found")
        }
        
        guard location.isActive else {
            throw Abort(.badRequest, reason: "Location is not active")
        }
        
        guard orderDTO.quantity > 0 else {
            throw Abort(.badRequest, reason: "Quantity must be greater than 0")
        }
        
        // Validate size if provided
        if let size = orderDTO.size {
            let validSizes = ["S", "M", "L"]
            guard validSizes.contains(size.uppercased()) else {
                throw Abort(.badRequest, reason: "Size must be S, M, or L")
            }
        }
        
        // Calculate price based on size
        var basePrice = coffeeType.price
        if let size = orderDTO.size {
            switch size.uppercased() {
            case "S":
                basePrice *= 0.9  // 10% discount for small
            case "M":
                basePrice *= 1.0  // Base price for medium
            case "L":
                basePrice *= 1.2  // 20% premium for large
            default:
                break
            }
        }
        
        let totalPrice = basePrice * Double(orderDTO.quantity)
        
        let order = Order(
            userID: user.id!,
            coffeeTypeID: orderDTO.coffeeTypeID,
            locationID: orderDTO.locationID,
            quantity: orderDTO.quantity,
            totalPrice: totalPrice,
            status: .pending,
            size: orderDTO.size,
            milkType: orderDTO.milkType,
            extras: orderDTO.extras,
            specialInstructions: orderDTO.specialInstructions
        )
        
        try await order.save(on: req.db)
        
        return OrderResponseDTO(from: order, coffeeType: coffeeType, location: location)
    }
    
    func update(req: Request) async throws -> OrderResponseDTO {
        let user = try req.auth.require(User.self)
        
        guard let order = try await Order.find(req.parameters.get("orderID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        if !user.isAdmin && order.$user.id != user.id {
            throw Abort(.forbidden)
        }
        
        let updateDTO = try req.content.decode(OrderUpdateDTO.self)
        
        if let status = updateDTO.status {
            if !user.isAdmin && status != .cancelled {
                throw Abort(.forbidden, reason: "Only admins can update order status")
            }
            order.status = status
        }
        
        if let size = updateDTO.size {
            // Validate size
            let validSizes = ["S", "M", "L"]
            guard validSizes.contains(size.uppercased()) else {
                throw Abort(.badRequest, reason: "Size must be S, M, or L")
            }
            order.size = size.uppercased()
            
            // Recalculate price if size changes
            let coffeeType = try await order.$coffeeType.get(on: req.db)
            var basePrice = coffeeType.price
            switch size.uppercased() {
            case "S":
                basePrice *= 0.9
            case "M":
                basePrice *= 1.0
            case "L":
                basePrice *= 1.2
            default:
                break
            }
            order.totalPrice = basePrice * Double(order.quantity)
        }
        if let milkType = updateDTO.milkType {
            order.milkType = milkType
        }
        if let extras = updateDTO.extras {
            order.extras = extras
        }
        if let specialInstructions = updateDTO.specialInstructions {
            order.specialInstructions = specialInstructions
        }
        
        try await order.save(on: req.db)
        
        let coffeeType = try await order.$coffeeType.get(on: req.db)
        let location = try await order.$location.get(on: req.db)
        
        return OrderResponseDTO(from: order, coffeeType: coffeeType, location: location)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let order = try await Order.find(req.parameters.get("orderID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        if !user.isAdmin && order.$user.id != user.id {
            throw Abort(.forbidden)
        }
        
        if order.status == .completed {
            throw Abort(.badRequest, reason: "Cannot delete completed orders")
        }
        
        try await order.delete(on: req.db)
        return .noContent
    }
}

