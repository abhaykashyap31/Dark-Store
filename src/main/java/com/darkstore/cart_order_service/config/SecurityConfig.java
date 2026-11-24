
package com.darkstore.cart_order_service.config;

import com.darkstore.cart_order_service.security.OrderIdentityFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.http.MediaType;

import java.io.IOException;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .httpBasic(AbstractHttpConfigurer::disable)
            .formLogin(AbstractHttpConfigurer::disable)
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                    .requestMatchers("/actuator/health/**", "/actuator/info", "/error").permitAll()
                    .anyRequest().authenticated())
            .exceptionHandling(errors -> errors
                    .authenticationEntryPoint((request, response, exception) ->
                            writeAuthError(response, 401, "TOKEN_INVALID", "Authentication required"))
                    .accessDeniedHandler((request, response, exception) ->
                            writeAuthError(response, 403, "ACCESS_DENIED", "You do not have permission to do this")))
            .addFilterBefore(new OrderIdentityFilter(), UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    private static void writeAuthError(
            jakarta.servlet.http.HttpServletResponse response,
            int status,
            String code,
            String message
    ) throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write(
                "{\"status\":" + status + ",\"code\":\"" + code + "\",\"message\":\"" + message + "\"}");
    }
}
