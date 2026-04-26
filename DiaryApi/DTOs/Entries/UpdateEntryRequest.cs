namespace DiaryApi.DTOs.Entries;
public record UpdateEntryRequest(string? Title, string? Content, int? Mood, List<Guid>? TagIds, bool? IsFavorite);
