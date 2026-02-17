package com.example.poc.controller.dto;

import jakarta.annotation.Nullable;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

public record CreateTaskRequestDto(
        @NotBlank(message = "제목은 필수입니다") String title,
        @Nullable String description,
        @NotBlank(message = "담당자는 필수입니다") String assignee,
        @Nullable LocalDate dueDate
) {
}
