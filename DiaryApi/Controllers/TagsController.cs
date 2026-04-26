using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using DiaryApi.DTOs.Tags;
using DiaryApi.Services;

namespace DiaryApi.Controllers;

[ApiController]
[Route("api/tags")]
[Authorize]
public class TagsController : ControllerBase
{
    private readonly ITagService _tags;
    private readonly ICurrentUserService _currentUser;
    public TagsController(ITagService tags, ICurrentUserService currentUser)
    {
        _tags = tags; _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<IActionResult> GetTags() => Ok(await _tags.GetTagsAsync(_currentUser.UserId));

    [HttpPost]
    public async Task<IActionResult> CreateTag([FromBody] CreateTagRequest request)
    {
        var tag = await _tags.CreateTagAsync(_currentUser.UserId, request);
        return CreatedAtAction(nameof(GetTags), tag);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateTag(Guid id, [FromBody] CreateTagRequest request)
    {
        var tag = await _tags.UpdateTagAsync(_currentUser.UserId, id, request);
        return Ok(tag);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteTag(Guid id)
    {
        await _tags.DeleteTagAsync(_currentUser.UserId, id);
        return NoContent();
    }
}
