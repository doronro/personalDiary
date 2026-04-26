namespace DiaryApi.DTOs.Entries;
using DiaryApi.DTOs.Tags;
public record EntryResponse(Guid Id, string Title, string Content, int? Mood, List<TagResponse> Tags, bool IsFavorite, int WordCount, DateTime CreatedAt, DateTime UpdatedAt);
