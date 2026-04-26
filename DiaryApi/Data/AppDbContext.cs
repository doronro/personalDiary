using Microsoft.EntityFrameworkCore;
using DiaryApi.Domain.Entities;

namespace DiaryApi.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<DiaryEntry> DiaryEntries => Set<DiaryEntry>();
    public DbSet<Tag> Tags => Set<Tag>();
    public DbSet<EntryTag> EntryTags => Set<EntryTag>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // User
        modelBuilder.Entity<User>(b => {
            b.HasKey(u => u.Id);
            b.HasIndex(u => u.Email).IsUnique();
            b.Property(u => u.Email).IsRequired().HasMaxLength(255);
            b.Property(u => u.DisplayName).IsRequired().HasMaxLength(100);
        });

        // DiaryEntry
        modelBuilder.Entity<DiaryEntry>(b => {
            b.HasKey(e => e.Id);
            b.HasIndex(e => new { e.UserId, e.CreatedAt });
            b.Property(e => e.Title).HasMaxLength(500);
            b.Property(e => e.Content).IsRequired();
            b.HasOne(e => e.User).WithMany(u => u.Entries).HasForeignKey(e => e.UserId).OnDelete(DeleteBehavior.Cascade);
            b.HasQueryFilter(e => e.DeletedAt == null);
        });

        // Tag
        modelBuilder.Entity<Tag>(b => {
            b.HasKey(t => t.Id);
            b.HasIndex(t => new { t.UserId, t.Name }).IsUnique();
            b.Property(t => t.Name).IsRequired().HasMaxLength(100);
            b.HasOne(t => t.User).WithMany(u => u.Tags).HasForeignKey(t => t.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // EntryTag
        modelBuilder.Entity<EntryTag>(b => {
            b.HasKey(et => new { et.EntryId, et.TagId });
            b.HasOne(et => et.Entry).WithMany(e => e.EntryTags).HasForeignKey(et => et.EntryId).OnDelete(DeleteBehavior.Cascade);
            b.HasOne(et => et.Tag).WithMany(t => t.EntryTags).HasForeignKey(et => et.TagId).OnDelete(DeleteBehavior.Cascade);
        });

        // RefreshToken
        modelBuilder.Entity<RefreshToken>(b => {
            b.HasKey(rt => rt.Id);
            b.HasIndex(rt => rt.TokenHash).IsUnique();
            b.HasOne(rt => rt.User).WithMany(u => u.RefreshTokens).HasForeignKey(rt => rt.UserId).OnDelete(DeleteBehavior.Cascade);
        });
    }
}
