package com.darkstore.auth.controller;

import com.darkstore.auth.dto.Dtos.AddressRequest;
import com.darkstore.auth.dto.Dtos.AddressResponse;
import com.darkstore.auth.dto.Dtos.UpdateProfileRequest;
import com.darkstore.auth.dto.Dtos.UserResponse;
import com.darkstore.auth.security.AuthUser;
import com.darkstore.auth.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users/me")
public class UserController {

    private final UserService users;

    public UserController(UserService users) {
        this.users = users;
    }

    @GetMapping
    public UserResponse me(@AuthenticationPrincipal AuthUser user) {
        return users.me(user.userId());
    }

    @PutMapping
    public UserResponse update(@AuthenticationPrincipal AuthUser user, @Valid @RequestBody UpdateProfileRequest r) {
        return users.updateMe(user.userId(), r);
    }

    @PreAuthorize("hasRole('CUSTOMER')")
    @GetMapping("/addresses")
    public List<AddressResponse> addresses(@AuthenticationPrincipal AuthUser user) {
        return users.listAddresses(user.userId());
    }

    @PreAuthorize("hasRole('CUSTOMER')")
    @PostMapping("/addresses")
    @ResponseStatus(HttpStatus.CREATED)
    public AddressResponse addAddress(@AuthenticationPrincipal AuthUser user, @Valid @RequestBody AddressRequest r) {
        return users.addAddress(user.userId(), r);
    }

    @PreAuthorize("hasRole('CUSTOMER')")
    @PutMapping("/addresses/{id}")
    public AddressResponse updateAddress(@AuthenticationPrincipal AuthUser user, @PathVariable UUID id,
                                         @Valid @RequestBody AddressRequest r) {
        return users.updateAddress(user.userId(), id, r);
    }

    @PreAuthorize("hasRole('CUSTOMER')")
    @DeleteMapping("/addresses/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAddress(@AuthenticationPrincipal AuthUser user, @PathVariable UUID id) {
        users.deleteAddress(user.userId(), id);
    }
}
