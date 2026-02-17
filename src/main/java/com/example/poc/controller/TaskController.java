package com.example.poc.controller;

import com.example.poc.controller.dto.CreateTaskRequestDto;
import com.example.poc.controller.dto.SimpleTaskDto;
import com.example.poc.controller.dto.UpdateTaskStatusRequestDto;
import com.example.poc.service.TaskService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    @GetMapping
    public List<SimpleTaskDto> getAllTasks() {
        return taskService.getAllTasks();
    }

    @GetMapping("/{id}")
    public SimpleTaskDto getTask(@PathVariable Long id) {
        return taskService.getTask(id);
    }

    @GetMapping("/assignee/{assignee}")
    public List<SimpleTaskDto> getTasksByAssignee(@PathVariable String assignee) {
        return taskService.getTasksByAssignee(assignee);
    }

    @GetMapping("/overdue")
    public List<SimpleTaskDto> getOverdueTasks() {
        return taskService.getOverdueTasks();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public SimpleTaskDto createTask(@Valid @RequestBody CreateTaskRequestDto request) {
        return taskService.createTask(request);
    }

    @PatchMapping("/{id}/status")
    public SimpleTaskDto updateTaskStatus(@PathVariable Long id,
                                          @Valid @RequestBody UpdateTaskStatusRequestDto request) {
        return taskService.updateTaskStatus(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteTask(@PathVariable Long id) {
        taskService.deleteTask(id);
    }
}
