using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace GrowthTracker.API.Migrations
{
    /// <inheritdoc />
    public partial class UpdateModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FocusArea",
                table: "Users",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "DailyTaskId",
                table: "Reminders",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "Reminders",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Category",
                table: "DailyTasks",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "CompletedAt",
                table: "DailyTasks",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "EstimatedMinutes",
                table: "DailyTasks",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "IsSelected",
                table: "DailyTasks",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "DailyTasks",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "TaskSelections",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    DailyTaskId = table.Column<int>(type: "integer", nullable: false),
                    SelectedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Status = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TaskSelections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TaskSelections_DailyTasks_DailyTaskId",
                        column: x => x.DailyTaskId,
                        principalTable: "DailyTasks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TaskSelections_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Reminders_DailyTaskId",
                table: "Reminders",
                column: "DailyTaskId");

            migrationBuilder.CreateIndex(
                name: "IX_Reminders_UserId",
                table: "Reminders",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_DailyTasks_UserId",
                table: "DailyTasks",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_TaskSelections_DailyTaskId",
                table: "TaskSelections",
                column: "DailyTaskId");

            migrationBuilder.CreateIndex(
                name: "IX_TaskSelections_UserId",
                table: "TaskSelections",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_DailyTasks_Users_UserId",
                table: "DailyTasks",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Reminders_DailyTasks_DailyTaskId",
                table: "Reminders",
                column: "DailyTaskId",
                principalTable: "DailyTasks",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Reminders_Users_UserId",
                table: "Reminders",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DailyTasks_Users_UserId",
                table: "DailyTasks");

            migrationBuilder.DropForeignKey(
                name: "FK_Reminders_DailyTasks_DailyTaskId",
                table: "Reminders");

            migrationBuilder.DropForeignKey(
                name: "FK_Reminders_Users_UserId",
                table: "Reminders");

            migrationBuilder.DropTable(
                name: "TaskSelections");

            migrationBuilder.DropIndex(
                name: "IX_Reminders_DailyTaskId",
                table: "Reminders");

            migrationBuilder.DropIndex(
                name: "IX_Reminders_UserId",
                table: "Reminders");

            migrationBuilder.DropIndex(
                name: "IX_DailyTasks_UserId",
                table: "DailyTasks");

            migrationBuilder.DropColumn(
                name: "FocusArea",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "DailyTaskId",
                table: "Reminders");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "Reminders");

            migrationBuilder.DropColumn(
                name: "Category",
                table: "DailyTasks");

            migrationBuilder.DropColumn(
                name: "CompletedAt",
                table: "DailyTasks");

            migrationBuilder.DropColumn(
                name: "EstimatedMinutes",
                table: "DailyTasks");

            migrationBuilder.DropColumn(
                name: "IsSelected",
                table: "DailyTasks");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "DailyTasks");
        }
    }
}
