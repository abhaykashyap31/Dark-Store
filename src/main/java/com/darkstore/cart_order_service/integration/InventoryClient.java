package com.darkstore.cart_order_service.integration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.math.BigDecimal;
import java.net.http.HttpClient;
import java.time.Duration;
import java.util.List;
import java.util.UUID;

@Component
public class InventoryClient {

    private final RestClient restClient;

    public InventoryClient(
            @Value("${inventory.service-url}") String serviceUrl,
            @Value("${inventory.internal-token}") String internalToken
    ) {
        if (internalToken == null || internalToken.isBlank()) {
            throw new IllegalArgumentException("Inventory internal token must not be blank");
        }

        var httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(2))
                .build();
        var requestFactory = new JdkClientHttpRequestFactory(httpClient);
        requestFactory.setReadTimeout(Duration.ofSeconds(5));

        this.restClient = RestClient.builder()
                .baseUrl(serviceUrl)
                .requestFactory(requestFactory)
                .defaultHeader("X-Internal-Service-Token", internalToken)
                .build();
    }

    public List<AvailableProduct> validateProducts(UUID storeId, List<UUID> productIds) {
        try {
            ValidateResponse response = restClient.post()
                    .uri("/internal/products/validate")
                    .body(new ValidateRequest(storeId, productIds))
                    .retrieve()
                    .body(ValidateResponse.class);
            if (response == null || response.items() == null) {
                throw new InventoryIntegrationException(502,
                        "Inventory returned an empty validation response", null);
            }
            return response.items();
        } catch (ResourceAccessException ex) {
            throw new InventoryIntegrationException(503, "Inventory service is unavailable", ex);
        } catch (RestClientResponseException ex) {
            int status = ex.getStatusCode().is5xxServerError()
                    ? 502
                    : ex.getStatusCode().value();
            throw new InventoryIntegrationException(status,
                    "Inventory service rejected product validation", ex);
        }
    }

    public ReservationResponse reserve(UUID orderId, UUID storeId, List<ReservationItem> items) {
        return post("/internal/inventory/reserve", new ReserveRequest(orderId, storeId, items),
                ReservationResponse.class);
    }

    public ReservationResponse release(UUID orderId) {
        return post("/internal/inventory/release", new OrderRequest(orderId), ReservationResponse.class);
    }

    public ReservationResponse confirm(UUID orderId) {
        return post("/internal/inventory/confirm", new OrderRequest(orderId), ReservationResponse.class);
    }

    private <T> T post(String path, Object request, Class<T> responseType) {
        try {
            T response = restClient.post()
                    .uri(path)
                    .body(request)
                    .retrieve()
                    .body(responseType);
            if (response == null) {
                throw new InventoryIntegrationException(502, "Inventory returned an empty response", null);
            }
            return response;
        } catch (ResourceAccessException ex) {
            throw new InventoryIntegrationException(503, "Inventory service is unavailable", ex);
        } catch (RestClientResponseException ex) {
            int status = ex.getStatusCode().is5xxServerError()
                    ? 502
                    : ex.getStatusCode().value();
            throw new InventoryIntegrationException(status,
                    "Inventory service rejected the request", ex);
        }
    }

    public record AvailableProduct(UUID productId, String name, int available, BigDecimal price) {}

    public record ReservationItem(UUID productId, int quantity) {}

    public record ReservationResponse(UUID orderId, String status, List<ReservationItemResult> items) {}

    public record ReservationItemResult(UUID productId, int quantity, String status, Integer available) {}

    public record ValidateRequest(UUID storeId, List<UUID> productIds) {}

    public record ValidateResponse(UUID storeId, List<AvailableProduct> items) {}

    public record ReserveRequest(UUID orderId, UUID storeId, List<ReservationItem> items) {}

    public record OrderRequest(UUID orderId) {}
}
