package com.example.poc.storage.entity;

public enum TaskStatus {
    TODO,
    IN_PROGRESS,
    IN_REVIEW,
    DONE;

    public boolean isTerminal() {
        return this == DONE;
    }
}
