package com.darkstore.gateway;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;


@Component
public class JwtAuthGatewayFilterFactory extends AbstractGatewayFilterFactory<JwtAuthGatewayFilterFactory.Config> {

    private final SecretKey key;

    public JwtAuthGatewayFilterFactory(@Value("${jwt.secret}") String secret) {
        super(Config.class);
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    @Override
    public GatewayFilter apply(Config config) {
        return (exchange, chain) -> {
            String header = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
            if (header == null || !header.startsWith("Bearer ")) {
                return reject(exchange, "TOKEN_INVALID", "Missing bearer token");
            }

            Claims claims;
            try {
                claims = Jwts.parser().verifyWith(key).build()
                        .parseSignedClaims(header.substring(7).trim())
                        .getPayload();
            } catch (ExpiredJwtException e) {
                return reject(exchange, "TOKEN_EXPIRED", "Access token expired");
            } catch (JwtException | IllegalArgumentException e) {
                return reject(exchange, "TOKEN_INVALID", "Access token is invalid");
            }

            String role = claims.get("role", String.class);
            if (claims.getSubject() == null || role == null) {
                return reject(exchange, "TOKEN_INVALID", "Access token is invalid");
            }
            Object storeId = claims.get("storeId");

            ServerHttpRequest request = exchange.getRequest().mutate().headers(h -> {
                h.remove("X-User-Id");
                h.remove("X-User-Role");
                h.remove("X-Store-Id");
                h.set("X-User-Id", claims.getSubject());
                h.set("X-User-Role", role);
                if (storeId != null) {
                    h.set("X-Store-Id", storeId.toString());
                }
            }).build();

            return chain.filter(exchange.mutate().request(request).build());
        };
    }

    private static Mono<Void> reject(ServerWebExchange exchange, String code, String message) {
        var response = exchange.getResponse();
        response.setStatusCode(HttpStatus.UNAUTHORIZED);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        String body = "{\"status\":401,\"code\":\"" + code + "\",\"message\":\"" + message + "\"}";
        DataBuffer buffer = response.bufferFactory().wrap(body.getBytes(StandardCharsets.UTF_8));
        return response.writeWith(Mono.just(buffer));
    }

    public static class Config {
    }
}
