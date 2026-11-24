package com.darkstore.inventory.security;

import com.darkstore.inventory.domain.Role;

import java.util.UUID;

public record AuthUser(UUID userId, Role role, UUID storeId) {
}
