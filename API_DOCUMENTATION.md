# Coffee Backend API Documentation

A fully functional coffee shop backend API built with Vapor 4, featuring authentication, coffee types, locations, and order management.

## Features

- **Authentication**: JWT-based user registration and login
- **Coffee Types**: CRUD operations for coffee menu items
- **Locations**: Manage coffee shop locations
- **Orders**: Complete order management system with status tracking
- **Role-based Access**: Admin and regular user roles

## API Endpoints

### Authentication

#### Register User
```
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "fullName": "John Doe",
  "phone": "+1234567890"
}

Response: {
  "user": {
    "id": "...",
    "email": "user@example.com",
    "fullName": "John Doe",
    "phone": "+1234567890",
    "isAdmin": false
  },
  "token": "jwt_token_here"
}
```

#### Login
```
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}

Response: {
  "user": {...},
  "token": "jwt_token_here"
}
```

#### Get Current User
```
GET /auth/me
Authorization: Bearer {token}

Response: {
  "id": "...",
  "email": "user@example.com",
  "fullName": "John Doe",
  ...
}
```

### Coffee Types

#### Get All Coffee Types
```
GET /coffee-types
GET /coffee-types?available=true  # Filter by availability

Response: [CoffeeType, ...]
```

#### Get Coffee Type by ID
```
GET /coffee-types/{id}

Response: CoffeeType
```

#### Create Coffee Type (Protected)
```
POST /coffee-types
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Espresso",
  "description": "Strong coffee",
  "price": 3.50,
  "imageURL": "https://...",
  "isAvailable": true
}
```

#### Update Coffee Type (Protected)
```
PUT /coffee-types/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "price": 4.00,
  "isAvailable": false
}
```

#### Delete Coffee Type (Protected)
```
DELETE /coffee-types/{id}
Authorization: Bearer {token}
```

### Locations

#### Get All Locations
```
GET /locations
GET /locations?active=true  # Filter by active status

Response: [Location, ...]
```

#### Get Location by ID
```
GET /locations/{id}

Response: Location
```

#### Create Location (Protected)
```
POST /locations
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Downtown Coffee Shop",
  "address": "123 Main St",
  "city": "New York",
  "state": "NY",
  "zipCode": "10001",
  "country": "USA",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "phone": "+1234567890",
  "isActive": true
}
```

#### Update Location (Protected)
```
PUT /locations/{id}
Authorization: Bearer {token}
```

#### Delete Location (Protected)
```
DELETE /locations/{id}
Authorization: Bearer {token}
```

### Orders

All order endpoints require authentication.

#### Get All Orders
```
GET /orders
Authorization: Bearer {token}

# Regular users see only their orders
# Admins see all orders
```

#### Get My Orders
```
GET /orders/my-orders
Authorization: Bearer {token}

Response: [OrderResponseDTO, ...]
```

#### Get Order by ID
```
GET /orders/{id}
Authorization: Bearer {token}
```

#### Create Order
```
POST /orders
Authorization: Bearer {token}
Content-Type: application/json

{
  "coffeeTypeID": "uuid-here",
  "locationID": "uuid-here",
  "quantity": 2,
  "specialInstructions": "Extra hot, please"
}

Response: OrderResponseDTO
```

#### Update Order
```
PUT /orders/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "confirmed",  # Only admins can change status (except cancelled)
  "specialInstructions": "Updated instructions"
}
```

#### Delete Order
```
DELETE /orders/{id}
Authorization: Bearer {token}

# Cannot delete completed orders
```

## Order Status Values

- `pending` - Order just created
- `confirmed` - Order confirmed by staff
- `preparing` - Coffee is being prepared
- `ready` - Order is ready for pickup
- `completed` - Order completed
- `cancelled` - Order cancelled

## Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer {jwt_token}
```

Tokens expire after 7 days. Get a new token by logging in again.

## Database Schema

### Users
- id (UUID)
- email (String, unique)
- password_hash (String)
- full_name (String)
- phone (String, optional)
- is_admin (Bool)
- created_at, updated_at

### Coffee Types
- id (UUID)
- name (String)
- description (String, optional)
- price (Double)
- image_url (String, optional)
- is_available (Bool)
- created_at, updated_at

### Locations
- id (UUID)
- name (String)
- address (String)
- city (String)
- state (String, optional)
- zip_code (String, optional)
- country (String)
- latitude, longitude (Double, optional)
- phone (String, optional)
- is_active (Bool)
- created_at, updated_at

### Orders
- id (UUID)
- user_id (UUID, foreign key)
- coffee_type_id (UUID, foreign key)
- location_id (UUID, foreign key)
- quantity (Int)
- total_price (Double)
- status (String: pending, confirmed, preparing, ready, completed, cancelled)
- special_instructions (String, optional)
- created_at, updated_at

## Environment Variables

Set these in your environment or `.env` file:

- `DATABASE_HOST` - Database host (default: localhost)
- `DATABASE_PORT` - Database port (default: 5432)
- `DATABASE_USERNAME` - Database username (default: vapor_username)
- `DATABASE_PASSWORD` - Database password (default: vapor_password)
- `DATABASE_NAME` - Database name (default: vapor_database)
- `JWT_SECRET` - Secret key for JWT signing (default: your-secret-key-change-in-production)

## Running the Application

1. Start the database:
```bash
docker compose up -d db
```

2. Run migrations and start server:
```bash
swift run
```

Migrations run automatically on startup.

## Example Usage

### 1. Register a new user
```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123",
    "fullName": "John Doe"
  }'
```

### 2. Create a coffee type (requires auth)
```bash
curl -X POST http://localhost:8080/coffee-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "Cappuccino",
    "description": "Espresso with steamed milk",
    "price": 4.50,
    "isAvailable": true
  }'
```

### 3. Create an order
```bash
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "coffeeTypeID": "coffee-type-uuid",
    "locationID": "location-uuid",
    "quantity": 1
  }'
```

## Security Notes

- Passwords are hashed using Bcrypt
- JWT tokens are signed with HS256
- Change `JWT_SECRET` in production
- Admin-only endpoints are protected
- Users can only access their own orders (unless admin)

