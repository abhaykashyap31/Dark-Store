package com.darkstore.auth.service;

import com.darkstore.auth.domain.Role;
import com.darkstore.auth.domain.User;
import com.darkstore.auth.domain.UserStatus;
import com.darkstore.auth.dto.Dtos.CreateStaffRequest;
import com.darkstore.auth.dto.Dtos.UserResponse;
import com.darkstore.auth.repo.StoreRepository;
import com.darkstore.auth.repo.UserRepository;
import com.darkstore.auth.exception.ApiException;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class AdminService {

    private final UserRepository users;
    private final StoreRepository stores;
    private final PasswordEncoder encoder;

    public AdminService(UserRepository users, StoreRepository stores, PasswordEncoder encoder) {
        this.users = users;
        this.stores = stores;
        this.encoder = encoder;
    }

    public UserResponse createStaff(CreateStaffRequest r) {
        if (r.role() != Role.MANAGER && r.role() != Role.RIDER) {
            throw ApiException.validation("role must be MANAGER or RIDER");
        }
        if (r.storeId() == null) {
            throw ApiException.validation("storeId is required for " + r.role());
        }
        if (!stores.existsById(r.storeId())) {
            throw ApiException.notFound("Store");
        }
        String email = r.email().trim().toLowerCase();
        if (users.existsByEmailIgnoreCase(email)) {
            throw new ApiException(HttpStatus.CONFLICT, "EMAIL_ALREADY_EXISTS", "Email is already registered");
        }
        User u = new User();
        u.setFullName(r.fullName().trim());
        u.setEmail(email);
        u.setPhone(r.phone());
        u.setPasswordHash(encoder.encode(r.password()));
        u.setRole(r.role());
        u.setStore(stores.findById(r.storeId()).orElseThrow(() -> ApiException.notFound("Store")));
        return UserResponse.from(users.save(u));
    }

    @Transactional(readOnly = true)
    public List<UserResponse> list(Role role) {
        List<User> found = role == null ? users.findAll(Sort.by("id")) : users.findByRoleOrderByIdAsc(role);
        return found.stream().map(UserResponse::from).toList();
    }

    public UserResponse setStatus(UUID adminId, UUID id, UserStatus status) {
        if (adminId.equals(id)) {
            throw ApiException.validation("You cannot change your own status");
        }
        User u = users.findById(id).orElseThrow(() -> ApiException.notFound("User"));
        u.setStatus(status);
        return UserResponse.from(users.save(u));
    }
}
