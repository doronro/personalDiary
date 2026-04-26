namespace DiaryApi.DTOs.Common;
public record PagedResult<T>(List<T> Data, PaginationInfo Pagination);
public record PaginationInfo(int Page, int PageSize, int TotalCount, int TotalPages, bool HasNext, bool HasPrevious);
