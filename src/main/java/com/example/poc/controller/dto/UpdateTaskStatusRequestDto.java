package com.example.poc.controller.dto;

import com.example.poc.storage.entity.TaskStatus;
import jakarta.validation.constraints.NotNull;

public record UpdateTaskStatusRequestDto(
        @NotNull(message = "상태값은 필수입니다") TaskStatus status
) {
}
