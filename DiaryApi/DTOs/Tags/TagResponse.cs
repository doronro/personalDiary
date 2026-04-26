namespace DiaryApi.DTOs.Tags;
public record TagResponse(Guid Id, string Name, string Color, int EntryCount = 0);
