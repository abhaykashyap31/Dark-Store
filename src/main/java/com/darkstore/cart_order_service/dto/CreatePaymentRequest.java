package com.darkstore.cart_order_service.dto;

import com.darkstore.cart_order_service.enums.PaymentMethod;
import jakarta.validation.constraints.NotNull;

public class CreatePaymentRequest {

    @NotNull(message = "Payment method is required")
    private PaymentMethod paymentMethod;

    public PaymentMethod getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(PaymentMethod paymentMethod) {
        this.paymentMethod = paymentMethod;
    }
}