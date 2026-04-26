namespace DiaryApi.DTOs.Auth;
public record AuthResponse(string AccessToken, string RefreshToken, DateTime ExpiresAt, UserSummary User);
public record UserSummary(Guid Id, string Email, string DisplayName, string? AvatarUrl);
