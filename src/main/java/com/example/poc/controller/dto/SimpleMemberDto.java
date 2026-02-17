package com.example.poc.controller.dto;

import com.example.poc.storage.entity.MemberRole;
import jakarta.annotation.Nullable;

public record SimpleMemberDto(
        Long id,
        String email,
        String name,
        MemberRole role,
        @Nullable String department
) {
}
