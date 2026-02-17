package com.example.poc.storage.repository;

import com.example.poc.storage.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;

public interface MemberRepository extends JpaRepository<Member, Long> {

    Optional<Member> findByEmail(String email);

    List<Member> findByDepartment(String department);

    boolean existsByEmail(String email);
}
