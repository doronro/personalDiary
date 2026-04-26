namespace DiaryApi.Domain.Entities;
public class EntryTag
{
    public Guid EntryId { get; set; }
    public Guid TagId { get; set; }
    public DiaryEntry Entry { get; set; } = null!;
    public Tag Tag { get; set; } = null!;
}
