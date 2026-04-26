namespace DiaryApi.Domain.Entities;
using DiaryApi.Domain.Common;
public class DiaryEntry : BaseEntity
{
    public Guid UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public int? Mood { get; set; }  // 1-10
    public bool IsFavorite { get; set; } = false;
    public int WordCount { get; set; }
    public DateTime? DeletedAt { get; set; }
    public User User { get; set; } = null!;
    public ICollection<EntryTag> EntryTags { get; set; } = new List<EntryTag>();
}
