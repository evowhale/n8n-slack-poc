package com.example.poc.controller.dto;

import com.example.poc.storage.entity.TaskStatus;
import jakarta.annotation.Nullable;

import java.time.LocalDate;

public record SimpleTaskDto(
        Long id,
        String title,
        @Nullable String description,
        TaskStatus status,
        String assignee,
        @Nullable LocalDate dueDate,
        boolean overdue
) {
}
