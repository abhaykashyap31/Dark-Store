
package com.darkstore.cart_order_service.service;

import com.darkstore.cart_order_service.entity.Order;
import com.darkstore.cart_order_service.entity.Payment;
import com.darkstore.cart_order_service.enums.PaymentMethod;
import com.darkstore.cart_order_service.enums.PaymentStatus;
import com.darkstore.cart_order_service.repository.OrderRepository;
import com.darkstore.cart_order_service.repository.PaymentRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class PaymentService {

    private final OrderRepository orderRepository;
    private final PaymentRepository paymentRepository;

    public PaymentService(
            OrderRepository orderRepository,
            PaymentRepository paymentRepository) {
        this.orderRepository = orderRepository;
        this.paymentRepository = paymentRepository;
    }

    @Transactional
    public Payment createPayment(
            UUID orderId,
            UUID userId,
            PaymentMethod paymentMethod) {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() ->
                        new RuntimeException("Order not found"));

        if (!order.getUserId().equals(userId)) {
            throw new RuntimeException("Unauthorized access");
        }

        List<Payment> existingPayments =
                paymentRepository.findByOrderId(orderId);

        if (!existingPayments.isEmpty()) {
            throw new RuntimeException(
                    "Payment already exists for this order");
        }

        Payment payment = new Payment();

        payment.setOrder(order);
        payment.setAmount(order.getTotalAmount());
        payment.setPaymentMethod(paymentMethod);
        payment.setPaymentStatus(PaymentStatus.PENDING);

        return paymentRepository.save(payment);
    }

    @Transactional
    public Payment processMockPayment(
            UUID paymentId,
            boolean success) {

        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() ->
                        new RuntimeException("Payment not found"));

        if (payment.getPaymentMethod() == PaymentMethod.COD) {
            throw new RuntimeException(
                    "COD payment must be collected on delivery");
        }

        if (payment.getPaymentStatus() != PaymentStatus.PENDING) {
            throw new RuntimeException(
                    "Payment has already been processed");
        }

        if (success) {
            payment.setPaymentStatus(PaymentStatus.SUCCESS);
        } else {
            payment.setPaymentStatus(PaymentStatus.FAILED);
        }

        payment.setTransactionReference(
                "MOCK-TXN-" + UUID.randomUUID()
        );

        return paymentRepository.save(payment);
    }

    @Transactional(readOnly = true)
    public Payment getPaymentDetails(UUID orderId, UUID userId) {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() ->
                        new RuntimeException("Order not found"));

        if (!order.getUserId().equals(userId)) {
            throw new RuntimeException("Unauthorized access");
        }

        return paymentRepository.findByOrderId(orderId)
                .stream()
                .findFirst()
                .orElseThrow(() ->
                        new RuntimeException("Payment not found"));
    }


    @Transactional
    public Payment collectCodPayment(UUID paymentId) {

        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() ->
                        new RuntimeException("Payment not found"));

        if (payment.getPaymentMethod() != PaymentMethod.COD) {
            throw new RuntimeException(
                    "This is not a COD payment");
        }

        if (payment.getPaymentStatus() != PaymentStatus.PENDING) {
            throw new RuntimeException(
                    "Payment has already been processed");
        }

        payment.setPaymentStatus(PaymentStatus.SUCCESS);

        payment.setTransactionReference(
                "COD-" + UUID.randomUUID()
        );

        return paymentRepository.save(payment);
    }

    @Transactional
public void refundSuccessfulPayment(UUID orderId) {

    List<Payment> payments =
            paymentRepository.findByOrderId(orderId);

    for (Payment payment : payments) {

        if (payment.getPaymentStatus() == PaymentStatus.SUCCESS) {

            payment.setPaymentStatus(PaymentStatus.REFUNDED);

            payment.setTransactionReference(
                    "MOCK-REFUND-" + UUID.randomUUID()
            );

            paymentRepository.save(payment);
        }
    }
}
}
