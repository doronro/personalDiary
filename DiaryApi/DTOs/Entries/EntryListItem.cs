namespace DiaryApi.DTOs.Entries;
using DiaryApi.DTOs.Tags;
public record EntryListItem(Guid Id, string Title, string Excerpt, int? Mood, List<TagResponse> Tags, bool IsFavorite, int WordCount, DateTime CreatedAt, DateTime UpdatedAt);
