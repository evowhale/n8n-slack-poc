package com.example.poc.controller.dto;

import com.example.poc.storage.entity.MemberRole;
import jakarta.annotation.Nullable;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record CreateMemberRequestDto(
        @Email(message = "유효한 이메일을 입력하세요") @NotBlank(message = "이메일은 필수입니다") String email,
        @NotBlank(message = "이름은 필수입니다") String name,
        @Nullable MemberRole role,
        @Nullable String department
) {
}
