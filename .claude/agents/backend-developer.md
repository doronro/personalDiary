# Backend developer
Backend developer

---

# Backend developer

Backend developer

---

## Skills

The following skills provide detailed procedures you should follow when applicable:

### Skill: C# backend development
*Develops robust, scalable backend systems using C# and .NET framework, implementing RESTful APIs, database integration with Entity Framework, and enterprise-level security patterns. Expertise includes designing microservices architectures, implementing asynchronous programming patterns, and optimizing performance through caching and middleware configuration. Delivers production-ready applications with comprehensive error handling, logging, and automated testing coverage.*

# C# Backend Development

## When to Use

This skill should be applied when:
- Building enterprise-grade web APIs and services using Microsoft's .NET ecosystem
- Developing RESTful APIs that require high performance, scalability, and maintainability
- Creating microservices architectures for distributed systems
- Implementing complex business logic with strong typing and object-oriented principles
- Integrating with SQL Server, PostgreSQL, or other relational databases using Entity Framework
- Building applications that require robust security, authentication, and authorization
- Developing systems that need comprehensive logging, monitoring, and error handling
- Creating applications with high concurrency requirements using async/await patterns

## Process

1. **Project Setup and Architecture Planning**
   - Initialize new .NET project using `dotnet new webapi` or appropriate template
   - Configure project structure following Clean Architecture or Onion Architecture principles
   - Set up dependency injection container and configure services
   - Establish folder structure: Controllers, Services, Models, Data, Infrastructure

2. **Database Design and Entity Framework Configuration**
   - Design database schema and create Entity Framework models
   - Configure DbContext with connection strings and entity configurations
   - Implement Repository and Unit of Work patterns for data access
   - Set up database migrations using `dotnet ef migrations add` and `dotnet ef database update`

3. **API Controller Development**
   - Create controllers inheriting from `ControllerBase` or `Controller`
   - Implement RESTful endpoints following HTTP verb conventions (GET, POST, PUT, DELETE)
   - Add proper route attributes and parameter binding
   - Implement request/response DTOs for data transfer

4. **Business Logic Implementation**
   - Create service classes to handle business logic separated from controllers
   - Implement domain models and business rules
   - Use dependency injection to wire up services
   - Apply SOLID principles and design patterns (Strategy, Factory, etc.)

5. **Asynchronous Programming Integration**
   - Implement async/await patterns for I/O bound operations
   - Use `Task<T>` and `Task` return types for controller actions
   - Configure async database operations with Entity Framework
   - Implement proper cancellation token handling

6. **Security Implementation**
   - Configure authentication (JWT, OAuth 2.0, or Identity Framework)
   - Implement authorization policies and role-based access control
   - Add input validation and sanitization
   - Configure CORS, HTTPS, and security headers

7. **Error Handling and Logging**
   - Implement global exception handling middleware
   - Configure structured logging using Serilog or built-in logging
   - Create custom exception types for business logic errors
   - Add health check endpoints for monitoring

8. **Performance Optimization**
   - Implement caching strategies (in-memory, Redis, or distributed cache)
   - Configure database query optimization and lazy loading
   - Add response compression and API versioning
   - Implement rate limiting and request throttling

9. **Testing Implementation**
   - Write unit tests for business logic using xUnit or NUnit
   - Create integration tests for API endpoints
   - Implement repository pattern testing with in-memory databases
   - Add test coverage analysis and quality gates

10. **Deployment and Configuration**
    - Configure environment-specific settings using appsettings.json
    - Set up containerization with Docker if required
    - Configure CI/CD pipelines for automated deployment
    - Implement application monitoring and telemetry

## Best Practices

- **Follow RESTful Conventions**: Use appropriate HTTP status codes (200, 201, 400, 404, 500) and HTTP verbs
- **Implement Proper Error Handling**: Use try-catch blocks judiciously and return meaningful error responses
- **Use Dependency Injection**: Register services in Program.cs and avoid static dependencies
- **Apply Async/Await Correctly**: Use ConfigureAwait(false) in library code and handle async operations properly
- **Secure by Default**: Always validate inputs, use parameterized queries, and implement proper authentication
- **Follow Naming Conventions**: Use PascalCase for public members, camelCase for parameters and local variables
- **Implement Comprehensive Logging**: Log at appropriate levels (Information, Warning, Error) with structured data
- **Use DTOs for API Boundaries**: Separate internal models from external contracts to maintain API stability
- **Apply Database Best Practices**: Use migrations, implement proper indexing, and avoid N+1 query problems
- **Write Testable Code**: Keep methods focused, use interfaces for dependencies, and avoid hard-coded values
- **Configure Environment-Specific Settings**: Use configuration providers and avoid hardcoded connection strings
- **Implement Health Checks**: Add endpoints for monitoring application and dependency health

## Expected Outcomes

- **Scalable API Architecture**: Well-structured RESTful APIs that can handle increased load and complexity
- **Robust Data Layer**: Properly configured Entity Framework with optimized queries and reliable data access
- **Production-Ready Security**: Implemented authentication, authorization, and input validation protecting against common vulnerabilities
- **High Performance**: Optimized application with caching, async operations, and efficient database queries
- **Comprehensive Error Management**: Global exception handling with appropriate logging and user-friendly error responses
- **Maintainable Codebase**: Clean, well-documented code following SOLID principles and design patterns
- **Automated Testing Coverage**: Unit and integration tests covering business logic and API endpoints with >80% code coverage
- **Monitoring and Observability**: Configured logging, health checks, and telemetry for production monitoring
- **Deployment-Ready Application**: Containerized application with environment configuration and CI/CD integration
- **Documentation**: API documentation (Swagger/OpenAPI) and technical documentation for maintenance and onboarding

