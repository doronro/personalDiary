using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using DiaryApi.DTOs.Entries;
using DiaryApi.Services;

namespace DiaryApi.Controllers;

[ApiController]
[Route("api/entries")]
[Authorize]
public class EntriesController : ControllerBase
{
    private readonly IEntryService _entries;
    private readonly ICurrentUserService _currentUser;
    public EntriesController(IEntryService entries, ICurrentUserService currentUser)
    {
        _entries = entries; _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<IActionResult> GetEntries(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        [FromQuery] int? mood = null,
        [FromQuery] string? tagIds = null)
    {
        var tagIdList = tagIds?.Split(',').Select(Guid.Parse).ToList();
        var result = await _entries.GetEntriesAsync(_currentUser.UserId, page, pageSize, search, mood, tagIdList);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetEntry(Guid id)
    {
        var entry = await _entries.GetEntryAsync(_currentUser.UserId, id);
        return Ok(entry);
    }

    [HttpPost]
    public async Task<IActionResult> CreateEntry([FromBody] CreateEntryRequest request)
    {
        var entry = await _entries.CreateEntryAsync(_currentUser.UserId, request);
        return CreatedAtAction(nameof(GetEntry), new { id = entry.Id }, entry);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateEntry(Guid id, [FromBody] UpdateEntryRequest request)
    {
        var entry = await _entries.UpdateEntryAsync(_currentUser.UserId, id, request);
        return Ok(entry);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteEntry(Guid id)
    {
        await _entries.DeleteEntryAsync(_currentUser.UserId, id);
        return NoContent();
    }
}
