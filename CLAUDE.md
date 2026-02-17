# n8n-slack-poc

n8n + Slack Bot + Claude Code 연동 POC 프로젝트

| 분류 | 기술 |
|------|------|
| Core | Java 21, Spring Boot 3.5, Gradle |
| Data | JPA (Hibernate), H2 (In-Memory) |

## 빌드 & 테스트

```bash
./gradlew build
./gradlew test
```

## 프로젝트 구조

```
src/main/java/com/example/poc/
├── controller/         # REST API 컨트롤러
│   └── dto/            # 요청/응답 DTO (record)
├── service/            # 비즈니스 로직
└── storage/
    ├── entity/         # JPA 엔티티
    └── repository/     # Spring Data JPA
```

## API 목록

- `GET /api/tasks` — 전체 태스크 조회
- `POST /api/tasks` — 태스크 생성
- `PATCH /api/tasks/{id}/status` — 태스크 상태 변경
- `GET /api/tasks/overdue` — 기한 초과 태스크 조회
- `GET /api/members` — 전체 멤버 조회
- `POST /api/members` — 멤버 생성