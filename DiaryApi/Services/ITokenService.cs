namespace DiaryApi.Services;
using DiaryApi.Domain.Entities;
public interface ITokenService
{
    string GenerateAccessToken(User user);
    string GenerateRefreshToken();
    string HashToken(string token);
    Guid GetUserIdFromToken(string token);
}
