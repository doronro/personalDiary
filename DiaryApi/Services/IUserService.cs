namespace DiaryApi.Services;
using DiaryApi.DTOs.Users;
public interface IUserService
{
    Task<UserProfileResponse> GetProfileAsync(Guid userId);
    Task<UserProfileResponse> UpdateProfileAsync(Guid userId, UpdateProfileRequest request);
    Task DeleteAccountAsync(Guid userId);
}
