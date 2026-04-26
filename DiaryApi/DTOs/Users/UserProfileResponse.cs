namespace DiaryApi.DTOs.Users;
public record UserProfileResponse(Guid Id, string Email, string DisplayName, string? AvatarUrl, DateTime CreatedAt, UserStats Stats);
public record UserStats(int TotalEntries, int TotalWords, int CurrentStreak, int LongestStreak, int FavoriteCount, int EntriesThisMonth);
