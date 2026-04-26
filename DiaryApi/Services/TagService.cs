namespace DiaryApi.Services;
using DiaryApi.Data;
using DiaryApi.Domain.Entities;
using DiaryApi.DTOs.Tags;
using Microsoft.EntityFrameworkCore;

public class TagService : ITagService
{
    private readonly AppDbContext _db;
    public TagService(AppDbContext db) => _db = db;

    public async Task<List<TagResponse>> GetTagsAsync(Guid userId) =>
        await _db.Tags
            .Where(t => t.UserId == userId)
            .Select(t => new TagResponse(t.Id, t.Name, t.Color, t.EntryTags.Count))
            .AsNoTracking()
            .ToListAsync();

    public async Task<TagResponse> CreateTagAsync(Guid userId, CreateTagRequest request)
    {
        if (await _db.Tags.AnyAsync(t => t.UserId == userId && t.Name == request.Name))
            throw new InvalidOperationException("Tag name already exists.");
        var tag = new Tag { UserId = userId, Name = request.Name, Color = request.Color };
        _db.Tags.Add(tag);
        await _db.SaveChangesAsync();
        return new TagResponse(tag.Id, tag.Name, tag.Color, 0);
    }

    public async Task<TagResponse> UpdateTagAsync(Guid userId, Guid tagId, CreateTagRequest request)
    {
        var tag = await _db.Tags.FirstOrDefaultAsync(t => t.Id == tagId && t.UserId == userId)
            ?? throw new KeyNotFoundException("Tag not found.");
        tag.Name = request.Name;
        tag.Color = request.Color;
        await _db.SaveChangesAsync();
        return new TagResponse(tag.Id, tag.Name, tag.Color);
    }

    public async Task DeleteTagAsync(Guid userId, Guid tagId)
    {
        var tag = await _db.Tags.FirstOrDefaultAsync(t => t.Id == tagId && t.UserId == userId)
            ?? throw new KeyNotFoundException("Tag not found.");
        _db.Tags.Remove(tag);
        await _db.SaveChangesAsync();
    }
}
