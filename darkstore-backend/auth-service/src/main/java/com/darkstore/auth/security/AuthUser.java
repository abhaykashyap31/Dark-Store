package com.darkstore.auth.security;

import com.darkstore.auth.domain.Role;
import java.util.UUID;

public record AuthUser(UUID userId, Role role, UUID storeId) {
}
