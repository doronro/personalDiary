namespace DiaryApi.Services;
using DiaryApi.Data;
using DiaryApi.Domain.Entities;
using DiaryApi.DTOs.Common;
using DiaryApi.DTOs.Entries;
using DiaryApi.DTOs.Tags;
using Microsoft.EntityFrameworkCore;

public class EntryService : IEntryService
{
    private readonly AppDbContext _db;
    public EntryService(AppDbContext db) => _db = db;

    public async Task<PagedResult<EntryListItem>> GetEntriesAsync(Guid userId, int page, int pageSize, string? search, int? mood, List<Guid>? tagIds)
    {
        var query = _db.DiaryEntries
            .Where(e => e.UserId == userId)
            .Include(e => e.EntryTags).ThenInclude(et => et.Tag)
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(e => e.Title.Contains(search) || e.Content.Contains(search));
        if (mood.HasValue)
            query = query.Where(e => e.Mood == mood.Value);
        if (tagIds != null && tagIds.Any())
            query = query.Where(e => e.EntryTags.Any(et => tagIds.Contains(et.TagId)));

        var total = await query.CountAsync();
        var entries = await query
            .OrderByDescending(e => e.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var items = entries.Select(e => new EntryListItem(
            e.Id, e.Title,
            e.Content.Length > 200 ? e.Content[..200] + "..." : e.Content,
            e.Mood,
            e.EntryTags.Select(et => new TagResponse(et.Tag.Id, et.Tag.Name, et.Tag.Color)).ToList(),
            e.IsFavorite, e.WordCount, e.CreatedAt, e.UpdatedAt)).ToList();

        return new PagedResult<EntryListItem>(items, new PaginationInfo(page, pageSize, total,
            (int)Math.Ceiling((double)total / pageSize), page * pageSize < total, page > 1));
    }

    public async Task<EntryResponse> GetEntryAsync(Guid userId, Guid entryId)
    {
        var entry = await _db.DiaryEntries
            .Where(e => e.Id == entryId && e.UserId == userId)
            .Include(e => e.EntryTags).ThenInclude(et => et.Tag)
            .AsNoTracking()
            .FirstOrDefaultAsync() ?? throw new KeyNotFoundException("Entry not found.");
        return MapToResponse(entry);
    }

    public async Task<EntryResponse> CreateEntryAsync(Guid userId, CreateEntryRequest request)
    {
        var entry = new DiaryEntry
        {
            UserId = userId,
            Title = request.Title,
            Content = request.Content,
            Mood = request.Mood,
            IsFavorite = request.IsFavorite,
            WordCount = CountWords(request.Content),
        };
        if (request.TagIds != null && request.TagIds.Any())
        {
            var validTags = await _db.Tags.Where(t => request.TagIds.Contains(t.Id) && t.UserId == userId).ToListAsync();
            foreach (var tag in validTags)
                entry.EntryTags.Add(new EntryTag { TagId = tag.Id });
        }
        _db.DiaryEntries.Add(entry);
        await _db.SaveChangesAsync();
        return await GetEntryAsync(userId, entry.Id);
    }

    public async Task<EntryResponse> UpdateEntryAsync(Guid userId, Guid entryId, UpdateEntryRequest request)
    {
        var entry = await _db.DiaryEntries
            .Where(e => e.Id == entryId && e.UserId == userId)
            .Include(e => e.EntryTags)
            .FirstOrDefaultAsync() ?? throw new KeyNotFoundException("Entry not found.");

        if (request.Title != null) entry.Title = request.Title;
        if (request.Content != null) { entry.Content = request.Content; entry.WordCount = CountWords(request.Content); }
        if (request.Mood.HasValue) entry.Mood = request.Mood.Value;
        if (request.IsFavorite.HasValue) entry.IsFavorite = request.IsFavorite.Value;
        entry.UpdatedAt = DateTime.UtcNow;

        if (request.TagIds != null)
        {
            entry.EntryTags.Clear();
            var validTags = await _db.Tags.Where(t => request.TagIds.Contains(t.Id) && t.UserId == userId).ToListAsync();
            foreach (var tag in validTags)
                entry.EntryTags.Add(new EntryTag { EntryId = entry.Id, TagId = tag.Id });
        }
        await _db.SaveChangesAsync();
        return await GetEntryAsync(userId, entry.Id);
    }

    public async Task DeleteEntryAsync(Guid userId, Guid entryId)
    {
        var entry = await _db.DiaryEntries.FirstOrDefaultAsync(e => e.Id == entryId && e.UserId == userId)
            ?? throw new KeyNotFoundException("Entry not found.");
        entry.DeletedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
    }

    private static EntryResponse MapToResponse(DiaryEntry e) =>
        new(e.Id, e.Title, e.Content, e.Mood,
            e.EntryTags.Select(et => new TagResponse(et.Tag.Id, et.Tag.Name, et.Tag.Color)).ToList(),
            e.IsFavorite, e.WordCount, e.CreatedAt, e.UpdatedAt);

    private static int CountWords(string text) =>
        string.IsNullOrWhiteSpace(text) ? 0 : text.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length;
}
