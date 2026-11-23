package com.darkstore.auth.service;

import com.darkstore.auth.domain.RefreshToken;
import com.darkstore.auth.domain.Role;
import com.darkstore.auth.domain.User;
import com.darkstore.auth.domain.UserStatus;
import com.darkstore.auth.dto.Dtos.AuthResponse;
import com.darkstore.auth.dto.Dtos.LoginRequest;
import com.darkstore.auth.dto.Dtos.RegisterRequest;
import com.darkstore.auth.dto.Dtos.UserResponse;
import com.darkstore.auth.repo.RefreshTokenRepository;
import com.darkstore.auth.repo.UserRepository;
import com.darkstore.auth.security.JwtService;
import com.darkstore.auth.exception.ApiException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;

@Service
public class AuthService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final long refreshDays;

    public AuthService(UserRepository users, RefreshTokenRepository refreshTokens, PasswordEncoder encoder,
                       JwtService jwt, @Value("${jwt.refresh-token-days}") long refreshDays) {
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.encoder = encoder;
        this.jwt = jwt;
        this.refreshDays = refreshDays;
    }

    @Transactional
    public UserResponse register(RegisterRequest r) {
        String email = r.email().trim().toLowerCase();
        if (users.existsByEmailIgnoreCase(email)) {
            throw new ApiException(HttpStatus.CONFLICT, "EMAIL_ALREADY_EXISTS", "Email is already registered");
        }
        User u = new User();
        u.setFullName(r.fullName().trim());
        u.setEmail(email);
        u.setPhone(r.phone());
        u.setPasswordHash(encoder.encode(r.password()));
        u.setRole(Role.CUSTOMER);
        return UserResponse.from(users.save(u));
    }

    @Transactional
    public AuthResponse login(LoginRequest r) {
        User u = users.findByEmailIgnoreCase(r.email().trim())
                .orElseThrow(AuthService::badCredentials);
        if (!encoder.matches(r.password(), u.getPasswordHash())) {
            throw badCredentials();
        }
        checkActive(u);
        return issue(u);
    }

    /** Refresh tokens work once: the old one is revoked and a new pair is returned. */
    @Transactional
    public AuthResponse refresh(String rawToken) {
        RefreshToken stored = refreshTokens.findByTokenHashAndRevokedFalse(hash(rawToken))
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "TOKEN_INVALID",
                        "Refresh token is invalid or already used"));
        stored.setRevoked(true);
        if (stored.getExpiresAt().isBefore(Instant.now())) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "TOKEN_EXPIRED", "Refresh token expired, please log in again");
        }
        User u = users.findById(stored.getUserId())
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "TOKEN_INVALID", "User no longer exists"));
        checkActive(u);
        return issue(u);
    }

    @Transactional
    public void logout(String rawToken) {
        refreshTokens.findByTokenHashAndRevokedFalse(hash(rawToken))
                .ifPresent(token -> token.setRevoked(true));
    }

    // ---------- helpers ----------

    private AuthResponse issue(User u) {
        byte[] bytes = new byte[48];
        RANDOM.nextBytes(bytes);
        String raw = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        refreshTokens.save(new RefreshToken(hash(raw), u, Instant.now().plus(refreshDays, ChronoUnit.DAYS)));
        return new AuthResponse(jwt.createAccessToken(u), raw, jwt.expiresInSeconds(), UserResponse.from(u));
    }

    private static void checkActive(User u) {
        if (u.getStatus() == UserStatus.DISABLED) {
            throw new ApiException(HttpStatus.FORBIDDEN, "ACCOUNT_DISABLED", "This account has been disabled");
        }
    }

    private static ApiException badCredentials() {
        return new ApiException(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS", "Email or password is wrong");
    }

    static String hash(String raw) {
        try {
            byte[] d = MessageDigest.getInstance("SHA-256").digest(raw.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(d);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
