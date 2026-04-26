namespace DiaryApi.Services;
using DiaryApi.DTOs.Common;
using DiaryApi.DTOs.Entries;
public interface IEntryService
{
    Task<PagedResult<EntryListItem>> GetEntriesAsync(Guid userId, int page, int pageSize, string? search, int? mood, List<Guid>? tagIds);
    Task<EntryResponse> GetEntryAsync(Guid userId, Guid entryId);
    Task<EntryResponse> CreateEntryAsync(Guid userId, CreateEntryRequest request);
    Task<EntryResponse> UpdateEntryAsync(Guid userId, Guid entryId, UpdateEntryRequest request);
    Task DeleteEntryAsync(Guid userId, Guid entryId);
}
