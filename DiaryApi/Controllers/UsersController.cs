using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using DiaryApi.DTOs.Users;
using DiaryApi.Services;

namespace DiaryApi.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IUserService _users;
    private readonly ICurrentUserService _currentUser;
    public UsersController(IUserService users, ICurrentUserService currentUser)
    {
        _users = users; _currentUser = currentUser;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetProfile() => Ok(await _users.GetProfileAsync(_currentUser.UserId));

    [HttpPut("me")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
        => Ok(await _users.UpdateProfileAsync(_currentUser.UserId, request));

    [HttpDelete("me")]
    public async Task<IActionResult> DeleteAccount()
    {
        await _users.DeleteAccountAsync(_currentUser.UserId);
        return NoContent();
    }
}
