namespace DiaryApi.Domain.Entities;
using DiaryApi.Domain.Common;
public class Tag : BaseEntity
{
    public Guid UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Color { get; set; } = "#6366F1";
    public User User { get; set; } = null!;
    public ICollection<EntryTag> EntryTags { get; set; } = new List<EntryTag>();
}
