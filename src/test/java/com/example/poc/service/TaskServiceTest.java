package com.example.poc.service;

import com.example.poc.controller.dto.CreateTaskRequestDto;
import com.example.poc.controller.dto.SimpleTaskDto;
import com.example.poc.storage.entity.TaskStatus;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
class TaskServiceTest {

    @Autowired
    private TaskService taskService;

    @Test
    void createTask_validRequest() {
        var request = new CreateTaskRequestDto("테스트 태스크", "설명", "kim", LocalDate.now().plusDays(7));

        SimpleTaskDto result = taskService.createTask(request);

        assertThat(result.id()).isNotNull();
        assertThat(result.title()).isEqualTo("테스트 태스크");
        assertThat(result.status()).isEqualTo(TaskStatus.TODO);
        assertThat(result.overdue()).isFalse();
    }

    @Test
    void getTask_notFound() {
        assertThatThrownBy(() -> taskService.getTask(999L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Task not found");
    }

    @Test
    void getOverdueTasks_returnsOnlyOverdue() {
        taskService.createTask(new CreateTaskRequestDto("과거 태스크", null, "kim", LocalDate.now().minusDays(1)));
        taskService.createTask(new CreateTaskRequestDto("미래 태스크", null, "kim", LocalDate.now().plusDays(7)));

        List<SimpleTaskDto> overdue = taskService.getOverdueTasks();

        assertThat(overdue).hasSize(1);
        assertThat(overdue.get(0).title()).isEqualTo("과거 태스크");
    }
}