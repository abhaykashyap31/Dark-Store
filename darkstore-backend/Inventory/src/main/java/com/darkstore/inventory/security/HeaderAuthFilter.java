package com.darkstore.inventory.security;

import com.darkstore.inventory.domain.Role;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.List;
import java.util.UUID;

public class HeaderAuthFilter extends OncePerRequestFilter {

    public static final String USER_ID = "X-User-Id";
    public static final String USER_ROLE = "X-User-Role";
    public static final String STORE_ID = "X-Store-Id";
    public static final String INTERNAL_SERVICE_TOKEN = "X-Internal-Service-Token";

    private final byte[] internalServiceToken;

    public HeaderAuthFilter(String internalServiceToken) {
        if (internalServiceToken == null || internalServiceToken.isBlank()) {
            throw new IllegalArgumentException("Inventory internal service token must not be blank");
        }
        this.internalServiceToken = internalServiceToken.getBytes(StandardCharsets.UTF_8);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String suppliedServiceToken = request.getHeader(INTERNAL_SERVICE_TOKEN);
        if (request.getRequestURI().startsWith("/internal/")
                && suppliedServiceToken != null
                && MessageDigest.isEqual(internalServiceToken,
                        suppliedServiceToken.getBytes(StandardCharsets.UTF_8))) {
            var authentication = new UsernamePasswordAuthenticationToken(
                    "order-service", null,
                    List.of(new SimpleGrantedAuthority("ROLE_ORDER_SERVICE")));
            SecurityContextHolder.getContext().setAuthentication(authentication);
            chain.doFilter(request, response);
            return;
        }

        String id = request.getHeader(USER_ID);
        String role = request.getHeader(USER_ROLE);
        String store = request.getHeader(STORE_ID);

        if (id != null && role != null) {
            try {
                UUID storeId = (store == null || store.isBlank()) ? null : UUID.fromString(store);
                AuthUser user = new AuthUser(UUID.fromString(id), Role.valueOf(role), storeId);
                var authentication = new UsernamePasswordAuthenticationToken(
                        user, null, List.of(new SimpleGrantedAuthority("ROLE_" + user.role().name())));
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (IllegalArgumentException ignored) {
                // Invalid forwarded identity values remain unauthenticated and are rejected by Spring Security.
            }
        }
        chain.doFilter(request, response);
    }
}
