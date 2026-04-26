namespace DiaryApi.Services;
using DiaryApi.Data;
using DiaryApi.DTOs.Users;
using Microsoft.EntityFrameworkCore;

public class UserService : IUserService
{
    private readonly AppDbContext _db;
    public UserService(AppDbContext db) => _db = db;

    public async Task<UserProfileResponse> GetProfileAsync(Guid userId)
    {
        var user = await _db.Users.FindAsync(userId) ?? throw new KeyNotFoundException("User not found.");
        var stats = await GetStatsAsync(userId);
        return new UserProfileResponse(user.Id, user.Email, user.DisplayName, user.AvatarUrl, user.CreatedAt, stats);
    }

    public async Task<UserProfileResponse> UpdateProfileAsync(Guid userId, UpdateProfileRequest request)
    {
        var user = await _db.Users.FindAsync(userId) ?? throw new KeyNotFoundException("User not found.");
        if (request.DisplayName != null) user.DisplayName = request.DisplayName;
        if (request.AvatarUrl != null) user.AvatarUrl = request.AvatarUrl;
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return await GetProfileAsync(userId);
    }

    public async Task DeleteAccountAsync(Guid userId)
    {
        var user = await _db.Users.FindAsync(userId) ?? throw new KeyNotFoundException("User not found.");
        _db.Users.Remove(user);
        await _db.SaveChangesAsync();
    }

    private async Task<UserStats> GetStatsAsync(Guid userId)
    {
        var entries = await _db.DiaryEntries.Where(e => e.UserId == userId).AsNoTracking().ToListAsync();
        var totalEntries = entries.Count;
        var totalWords = entries.Sum(e => e.WordCount);
        var favoriteCount = entries.Count(e => e.IsFavorite);
        var now = DateTime.UtcNow;
        var entriesThisMonth = entries.Count(e => e.CreatedAt.Month == now.Month && e.CreatedAt.Year == now.Year);

        // Calculate streak
        var dates = entries.Select(e => e.CreatedAt.Date).Distinct().OrderByDescending(d => d).ToList();
        int currentStreak = 0, longestStreak = 0, tempStreak = 0;
        var today = DateTime.UtcNow.Date;
        for (int i = 0; i < dates.Count; i++)
        {
            if (i == 0 && (dates[0] == today || dates[0] == today.AddDays(-1))) { tempStreak = 1; }
            else if (i > 0 && (dates[i - 1] - dates[i]).Days == 1) { tempStreak++; }
            else { tempStreak = 1; }
            if (i == 0 || (i == 1 && dates[0] == today)) currentStreak = tempStreak;
            longestStreak = Math.Max(longestStreak, tempStreak);
        }
        return new UserStats(totalEntries, totalWords, currentStreak, longestStreak, favoriteCount, entriesThisMonth);
    }
}
