namespace DiaryApi.Services;
using DiaryApi.DTOs.Tags;
public interface ITagService
{
    Task<List<TagResponse>> GetTagsAsync(Guid userId);
    Task<TagResponse> CreateTagAsync(Guid userId, CreateTagRequest request);
    Task<TagResponse> UpdateTagAsync(Guid userId, Guid tagId, CreateTagRequest request);
    Task DeleteTagAsync(Guid userId, Guid tagId);
}
