package com.example.poc.service;

import com.example.poc.controller.dto.CreateMemberRequestDto;
import com.example.poc.controller.dto.SimpleMemberDto;
import com.example.poc.storage.entity.Member;
import com.example.poc.storage.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MemberService {

    private final MemberRepository memberRepository;

    @Transactional(readOnly = true)
    public List<SimpleMemberDto> getAllMembers() {
        return memberRepository.findAll().stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public SimpleMemberDto getMember(Long id) {
        Member member = memberRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Member not found: " + id));
        return toDto(member);
    }

    @Transactional
    public SimpleMemberDto createMember(CreateMemberRequestDto request) {
        if (memberRepository.existsByEmail(request.email())) {
            throw new IllegalStateException("Email already exists: " + request.email());
        }

        Member member = Member.builder()
                .email(request.email())
                .name(request.name())
                .role(request.role())
                .department(request.department())
                .build();

        Member saved = memberRepository.save(member);
        return toDto(saved);
    }

    private SimpleMemberDto toDto(Member member) {
        return new SimpleMemberDto(
                member.getId(),
                member.getEmail(),
                member.getName(),
                member.getRole(),
                member.getDepartment()
        );
    }
}
