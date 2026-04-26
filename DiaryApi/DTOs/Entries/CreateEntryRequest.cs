namespace DiaryApi.DTOs.Entries;
public record CreateEntryRequest(string Title, string Content, int? Mood, List<Guid>? TagIds, bool IsFavorite = false);
