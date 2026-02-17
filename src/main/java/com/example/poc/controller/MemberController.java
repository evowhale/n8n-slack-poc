package com.example.poc.controller;

import com.example.poc.controller.dto.CreateMemberRequestDto;
import com.example.poc.controller.dto.SimpleMemberDto;
import com.example.poc.service.MemberService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/members")
@RequiredArgsConstructor
public class MemberController {

    private final MemberService memberService;

    @GetMapping
    public List<SimpleMemberDto> getAllMembers() {
        return memberService.getAllMembers();
    }

    @GetMapping("/{id}")
    public SimpleMemberDto getMember(@PathVariable Long id) {
        return memberService.getMember(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public SimpleMemberDto createMember(@Valid @RequestBody CreateMemberRequestDto request) {
        return memberService.createMember(request);
    }
}
