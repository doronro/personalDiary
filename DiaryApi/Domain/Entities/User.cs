namespace DiaryApi.Domain.Entities;
using DiaryApi.Domain.Common;
public class User : BaseEntity
{
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public bool IsActive { get; set; } = true;
    public ICollection<DiaryEntry> Entries { get; set; } = new List<DiaryEntry>();
    public ICollection<Tag> Tags { get; set; } = new List<Tag>();
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
}
