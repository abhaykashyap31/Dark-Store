package com.darkstore.gateway;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.RouterFunctions;
import org.springframework.web.reactive.function.server.ServerResponse;

import java.net.URI;

import static org.springframework.web.reactive.function.server.RequestPredicates.GET;

@Configuration
public class AdminPageConfig {

    @Bean
    RouterFunction<ServerResponse> adminRedirect() {
        return RouterFunctions
                .route(GET("/admin"), r -> ServerResponse.temporaryRedirect(URI.create("/admin/login.html")).build())
                .andRoute(GET("/admin/"), r -> ServerResponse.temporaryRedirect(URI.create("/admin/login.html")).build());
    }
}
