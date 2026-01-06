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
        
        let totalPrice = coffeeType.price * Double(orderDTO.quantity)
        
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
            order.size = size
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

