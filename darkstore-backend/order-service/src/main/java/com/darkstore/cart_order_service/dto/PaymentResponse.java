
package com.darkstore.cart_order_service.dto;

import com.darkstore.cart_order_service.entity.Payment;
import com.darkstore.cart_order_service.enums.PaymentMethod;
import com.darkstore.cart_order_service.enums.PaymentStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public class PaymentResponse {

    private UUID paymentId;
    private UUID orderId;
    private BigDecimal amount;
    private PaymentMethod paymentMethod;
    private PaymentStatus paymentStatus;
    private String transactionReference;
    private LocalDateTime createdAt;

    public PaymentResponse(Payment payment) {
        this.paymentId = payment.getId();
        this.orderId = payment.getOrder().getId();
        this.amount = payment.getAmount();
        this.paymentMethod = payment.getPaymentMethod();
        this.paymentStatus = payment.getPaymentStatus();
        this.transactionReference = payment.getTransactionReference();
        this.createdAt = payment.getCreatedAt();
    }

    public UUID getPaymentId() {
        return paymentId;
    }

    public UUID getOrderId() {
        return orderId;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public PaymentMethod getPaymentMethod() {
        return paymentMethod;
    }

    public PaymentStatus getPaymentStatus() {
        return paymentStatus;
    }

    public String getTransactionReference() {
        return transactionReference;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
