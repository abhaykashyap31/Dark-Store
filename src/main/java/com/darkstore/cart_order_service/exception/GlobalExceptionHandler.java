package com.darkstore.cart_order_service.exception;

import jakarta.validation.ConstraintViolationException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.NoSuchElementException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log =
            LoggerFactory.getLogger(GlobalExceptionHandler.class);

    private ResponseEntity<ErrorResponse> createResponse(
            HttpStatus status,
            String message,
            Map<String, String> validationErrors) {

        ErrorResponse response = new ErrorResponse(
                LocalDateTime.now(),
                status.value(),
                status.getReasonPhrase(),
                message,
                validationErrors
        );

        return ResponseEntity.status(status).body(response);
    }

    // 400 - Invalid input
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> handleIllegalArgument(
            IllegalArgumentException ex) {

        return createResponse(
                HttpStatus.BAD_REQUEST,
                ex.getMessage(),
                Map.of()
        );
    }

    // 400 - DTO validation errors
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException ex) {

        Map<String, String> errors = new HashMap<>();

        ex.getBindingResult().getFieldErrors().forEach(error ->
                errors.put(error.getField(), error.getDefaultMessage())
        );

        return createResponse(
                HttpStatus.BAD_REQUEST,
                "Validation failed",
                errors
        );
    }

    // 400 - Invalid JSON or enum value
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleInvalidJson(
            HttpMessageNotReadableException ex) {

        return createResponse(
                HttpStatus.BAD_REQUEST,
                "Invalid request body or JSON format",
                Map.of()
        );
    }

    // 400 - Request parameter validation
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolation(
            ConstraintViolationException ex) {

        return createResponse(
                HttpStatus.BAD_REQUEST,
                ex.getMessage(),
                Map.of()
        );
    }

    // 404 - Resource not found
    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(
            NoSuchElementException ex) {

        return createResponse(
                HttpStatus.NOT_FOUND,
                ex.getMessage(),
                Map.of()
        );
    }

    // 405 - Unsupported HTTP method
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ErrorResponse> handleMethodNotSupported(
            HttpRequestMethodNotSupportedException ex) {

        return createResponse(
                HttpStatus.METHOD_NOT_ALLOWED,
                "HTTP method not supported for this endpoint",
                Map.of()
        );
    }

    // 409 - Database constraint violation
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorResponse> handleDatabaseConflict(
            DataIntegrityViolationException ex) {

        log.warn("Database constraint violation", ex);

        return createResponse(
                HttpStatus.CONFLICT,
                "Operation conflicts with existing database data",
                Map.of()
        );
    }

    // 500 - Unexpected exception
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpectedException(
            Exception ex) {

        log.error("Unexpected application error", ex);

        return createResponse(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "An unexpected error occurred",
                Map.of()
        );
    }
}