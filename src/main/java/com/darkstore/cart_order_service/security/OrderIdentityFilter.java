package com.darkstore.cart_order_service.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.UUID;

public class OrderIdentityFilter extends OncePerRequestFilter {

    private static final Set<String> ROLES = Set.of("CUSTOMER", "MANAGER", "RIDER", "ADMIN");

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain chain
    ) throws ServletException, IOException {
        String userId = request.getHeader("X-User-Id");
        String role = request.getHeader("X-User-Role");
        if (userId != null && role != null && ROLES.contains(role)) {
            try {
                String store = request.getHeader("X-Store-Id");
                UUID storeId = store == null || store.isBlank() ? null : UUID.fromString(store);
                if (("MANAGER".equals(role) || "RIDER".equals(role)) && storeId == null) {
                    throw new IllegalArgumentException("Store identity is required for this role");
                }
                if ("RIDER".equals(role)
                        && !userId.equals(request.getHeader("X-Rider-Id"))) {
                    throw new IllegalArgumentException("Rider identity does not match the authenticated user");
                }
                OrderIdentity identity = new OrderIdentity(
                        UUID.fromString(userId),
                        role,
                        storeId
                );
                var authentication = new UsernamePasswordAuthenticationToken(
                        identity,
                        null,
                        List.of(new SimpleGrantedAuthority("ROLE_" + role))
                );
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (IllegalArgumentException ignored) {
                SecurityContextHolder.clearContext();
            }
        }
        chain.doFilter(request, response);
    }
}
