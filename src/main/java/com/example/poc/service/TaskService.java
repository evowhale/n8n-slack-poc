package com.example.poc.service;

import com.example.poc.controller.dto.CreateTaskRequestDto;
import com.example.poc.controller.dto.SimpleTaskDto;
import com.example.poc.controller.dto.UpdateTaskStatusRequestDto;
import com.example.poc.storage.entity.Task;
import com.example.poc.storage.entity.TaskStatus;
import com.example.poc.storage.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;

    @Transactional(readOnly = true)
    public List<SimpleTaskDto> getAllTasks() {
        return taskRepository.findAll().stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public SimpleTaskDto getTask(Long id) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Task not found: " + id));
        return toDto(task);
    }

    @Transactional(readOnly = true)
    public List<SimpleTaskDto> getTasksByAssignee(String assignee) {
        return taskRepository.findByAssignee(assignee).stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<SimpleTaskDto> getOverdueTasks() {
        return taskRepository.findOverdueTasks(LocalDate.now()).stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional
    public SimpleTaskDto createTask(CreateTaskRequestDto request) {
        Task task = Task.builder()
                .title(request.title())
                .description(request.description())
                .assignee(request.assignee())
                .dueDate(request.dueDate())
                .build();

        Task saved = taskRepository.save(task);
        return toDto(saved);
    }

    @Transactional
    public SimpleTaskDto updateTaskStatus(Long id, UpdateTaskStatusRequestDto request) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Task not found: " + id));

        task.updateStatus(request.status());
        return toDto(task);
    }

    @Transactional
    public void deleteTask(Long id) {
        if (!taskRepository.existsById(id)) {
            throw new IllegalArgumentException("Task not found: " + id);
        }
        taskRepository.deleteById(id);
    }

    private SimpleTaskDto toDto(Task task) {
        return new SimpleTaskDto(
                task.getId(),
                task.getTitle(),
                task.getDescription(),
                task.getStatus(),
                task.getAssignee(),
                task.getDueDate(),
                task.isOverdue()
        );
    }
}
