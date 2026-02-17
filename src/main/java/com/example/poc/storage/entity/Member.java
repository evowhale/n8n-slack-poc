package com.example.poc.storage.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "members")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    private MemberRole role;

    private String department;

    private LocalDateTime createdAt;

    @Builder
    public Member(String email, String name, MemberRole role, String department) {
        this.email = email;
        this.name = name;
        this.role = role != null ? role : MemberRole.MEMBER;
        this.department = department;
        this.createdAt = LocalDateTime.now();
    }

    public boolean isAdmin() {
        return this.role == MemberRole.ADMIN;
    }
}
