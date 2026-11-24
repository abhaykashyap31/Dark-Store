package com.darkstore.auth.security;

import com.darkstore.auth.domain.User;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {

    private final SecretKey key;
    private final long accessMinutes;

    public JwtService(@Value("${jwt.secret}") String secret,
                      @Value("${jwt.access-token-minutes}") long accessMinutes) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessMinutes = accessMinutes;
    }

    public String createAccessToken(User user) {
        Date now = new Date();
        var builder = Jwts.builder()
                .subject(String.valueOf(user.getId()))
                .claim("userId", user.getId())
                .claim("role", user.getRole().name());
        if (user.getStoreId() != null) {
            builder.claim("storeId", user.getStoreId());
        }
        return builder
                .issuedAt(now)
                .expiration(new Date(now.getTime() + accessMinutes * 60_000))
                .signWith(key)
                .compact();
    }

    public long expiresInSeconds() {
        return accessMinutes * 60;
    }
}
