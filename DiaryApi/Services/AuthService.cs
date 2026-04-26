namespace DiaryApi.Services;
using DiaryApi.Data;
using DiaryApi.Domain.Entities;
using DiaryApi.DTOs.Auth;
using Microsoft.EntityFrameworkCore;

public class AuthService : IAuthService
{
    private readonly AppDbContext _db;
    private readonly ITokenService _tokenService;
    private readonly IConfiguration _config;

    public AuthService(AppDbContext db, ITokenService tokenService, IConfiguration config)
    {
        _db = db; _tokenService = tokenService; _config = config;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
    {
        if (await _db.Users.AnyAsync(u => u.Email == request.Email.ToLowerInvariant()))
            throw new InvalidOperationException("Email already in use.");
        var user = new User
        {
            Email = request.Email.ToLowerInvariant(),
            DisplayName = request.DisplayName,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync();
        return await CreateTokenResponse(user);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == request.Email.ToLowerInvariant())
            ?? throw new UnauthorizedAccessException("Invalid credentials.");
        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new UnauthorizedAccessException("Invalid credentials.");
        return await CreateTokenResponse(user);
    }

    public async Task<AuthResponse> RefreshAsync(string refreshToken)
    {
        var hash = _tokenService.HashToken(refreshToken);
        var token = await _db.RefreshTokens
            .Include(rt => rt.User)
            .FirstOrDefaultAsync(rt => rt.TokenHash == hash && !rt.IsRevoked && rt.ExpiresAt > DateTime.UtcNow)
            ?? throw new UnauthorizedAccessException("Invalid or expired refresh token.");
        token.IsRevoked = true;
        token.RevokedAt = DateTime.UtcNow;
        var response = await CreateTokenResponse(token.User);
        await _db.SaveChangesAsync();
        return response;
    }

    public async Task LogoutAsync(string refreshToken)
    {
        var hash = _tokenService.HashToken(refreshToken);
        var token = await _db.RefreshTokens.FirstOrDefaultAsync(rt => rt.TokenHash == hash);
        if (token != null)
        {
            token.IsRevoked = true;
            token.RevokedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
        }
    }

    private async Task<AuthResponse> CreateTokenResponse(User user)
    {
        var rawRefresh = _tokenService.GenerateRefreshToken();
        var refreshDays = int.Parse(_config["JwtSettings:RefreshTokenExpirationDays"] ?? "30");
        var refreshEntity = new RefreshToken
        {
            UserId = user.Id,
            TokenHash = _tokenService.HashToken(rawRefresh),
            ExpiresAt = DateTime.UtcNow.AddDays(refreshDays),
        };
        _db.RefreshTokens.Add(refreshEntity);
        await _db.SaveChangesAsync();
        var accessToken = _tokenService.GenerateAccessToken(user);
        var expMins = int.Parse(_config["JwtSettings:AccessTokenExpirationMinutes"] ?? "15");
        return new AuthResponse(
            accessToken,
            rawRefresh,
            DateTime.UtcNow.AddMinutes(expMins),
            new UserSummary(user.Id, user.Email, user.DisplayName, user.AvatarUrl));
    }
}
