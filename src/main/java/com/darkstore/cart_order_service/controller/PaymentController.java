
package com.darkstore.cart_order_service.controller;

import com.darkstore.cart_order_service.dto.CreatePaymentRequest;
import com.darkstore.cart_order_service.dto.PaymentResponse;
import com.darkstore.cart_order_service.entity.Payment;
import com.darkstore.cart_order_service.service.PaymentService;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    // Create payment for an order
    @PostMapping("/orders/{orderId}/payments")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<PaymentResponse> createPayment(
            @PathVariable UUID orderId,
            @RequestHeader("X-USER-ID") UUID userId,
            @Valid @RequestBody CreatePaymentRequest request) {

        Payment payment = paymentService.createPayment(
                orderId,
                userId,
                request.getPaymentMethod()
        );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(new PaymentResponse(payment));
    }

    // Process mock payment
    @PostMapping("/payments/{paymentId}/process")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<PaymentResponse> processPayment(
            @PathVariable UUID paymentId,
            @RequestParam boolean success,
            @RequestHeader("X-USER-ID") UUID userId) {

        Payment payment = paymentService.processMockPayment(
                paymentId,
                userId,
                success
        );

        return ResponseEntity.ok(new PaymentResponse(payment));
    }

    @GetMapping("/orders/{orderId}/payments")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<PaymentResponse> getPaymentDetails(
            @PathVariable UUID orderId,
            @RequestHeader("X-USER-ID") UUID userId) {

        Payment payment = paymentService.getPaymentDetails(
                orderId, userId
        );

        return ResponseEntity.ok(new PaymentResponse(payment));
    }

    @PostMapping("/payments/{paymentId}/collect-cod")
    @PreAuthorize("hasRole('RIDER')")
    public ResponseEntity<PaymentResponse> collectCodPayment(
            @PathVariable UUID paymentId,
            @RequestHeader("X-RIDER-ID") UUID riderId) {

        Payment payment = paymentService.collectCodPayment(paymentId, riderId);

        return ResponseEntity.ok(new PaymentResponse(payment));
    }
}
