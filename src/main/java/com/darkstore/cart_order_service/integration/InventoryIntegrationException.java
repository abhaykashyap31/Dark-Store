package com.darkstore.cart_order_service.integration;

public class InventoryIntegrationException extends RuntimeException {

    private final int status;

    public InventoryIntegrationException(int status, String message, Throwable cause) {
        super(message, cause);
        this.status = status;
    }

    public int getStatus() {
        return status;
    }
}
