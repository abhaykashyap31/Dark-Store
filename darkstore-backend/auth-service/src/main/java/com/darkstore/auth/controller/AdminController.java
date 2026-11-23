package com.darkstore.auth.controller;

import com.darkstore.auth.domain.Role;
import com.darkstore.auth.dto.Dtos.CreateStaffRequest;
import com.darkstore.auth.dto.Dtos.StatusRequest;
import com.darkstore.auth.dto.Dtos.UserResponse;
import com.darkstore.auth.security.AuthUser;
import com.darkstore.auth.service.AdminService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin/users")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AdminService admin;

    public AdminController(AdminService admin) {
        this.admin = admin;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse create(@Valid @RequestBody CreateStaffRequest r) {
        return admin.createStaff(r);
    }

    @GetMapping
    public List<UserResponse> list(@RequestParam(required = false) Role role) {
        return admin.list(role);
    }

    @PatchMapping("/{id}/status")
    public UserResponse status(@AuthenticationPrincipal AuthUser user, @PathVariable UUID id,
                               @Valid @RequestBody StatusRequest r) {
        return admin.setStatus(user.userId(), id, r.status());
    }
}
