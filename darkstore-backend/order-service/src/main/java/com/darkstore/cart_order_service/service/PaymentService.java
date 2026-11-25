
package com.darkstore.cart_order_service.service;

import com.darkstore.cart_order_service.entity.Order;
import com.darkstore.cart_order_service.entity.Payment;
import com.darkstore.cart_order_service.enums.PaymentMethod;
import com.darkstore.cart_order_service.enums.PaymentStatus;
import com.darkstore.cart_order_service.repository.OrderRepository;
import com.darkstore.cart_order_service.repository.PaymentRepository;
import com.darkstore.cart_order_service.repository.OrderStatusHistoryRepository;
import com.darkstore.cart_order_service.integration.InventoryClient;
import com.darkstore.cart_order_service.entity.OrderStatusHistory;
import com.darkstore.cart_order_service.enums.OrderStatus;
import com.darkstore.cart_order_service.entity.RiderAssignment;
import com.darkstore.cart_order_service.enums.AssignmentStatus;
import com.darkstore.cart_order_service.repository.RiderAssignmentRepository;
import org.springframework.security.access.AccessDeniedException;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;

@Service
public class PaymentService {

    private final OrderRepository orderRepository;
    private final PaymentRepository paymentRepository;
    private final OrderStatusHistoryRepository historyRepository;
    private final InventoryClient inventoryClient;
    private final RiderAssignmentRepository riderAssignmentRepository;

    public PaymentService(
            OrderRepository orderRepository,
            PaymentRepository paymentRepository,
            OrderStatusHistoryRepository historyRepository,
            InventoryClient inventoryClient,
            RiderAssignmentRepository riderAssignmentRepository) {
        this.orderRepository = orderRepository;
        this.paymentRepository = paymentRepository;
        this.historyRepository = historyRepository;
        this.inventoryClient = inventoryClient;
        this.riderAssignmentRepository = riderAssignmentRepository;
    }

    @Transactional
    public Payment createPayment(
            UUID orderId,
            UUID userId,
            PaymentMethod paymentMethod) {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() ->
                        new NoSuchElementException("Order not found"));

        if (!order.getUserId().equals(userId)) {
            throw new AccessDeniedException("Unauthorized access");
        }
        if (order.getStatus() != OrderStatus.PLACED) {
            throw new IllegalStateException("Payment can only be processed for a newly placed order");
        }

        List<Payment> existingPayments =
                paymentRepository.findByOrderId(orderId);

        if (!existingPayments.isEmpty()) {
            throw new IllegalStateException(
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
            UUID userId,
            boolean success) {

        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() ->
                        new NoSuchElementException("Payment not found"));
        Order order = payment.getOrder();

        if (!order.getUserId().equals(userId)) {
            throw new AccessDeniedException("Unauthorized access");
        }
        if (order.getStatus() != OrderStatus.PLACED) {
            throw new IllegalStateException("Payment can only be processed for a newly placed order");
        }

        if (payment.getPaymentMethod() == PaymentMethod.COD) {
            throw new IllegalStateException(
                    "COD payment must be collected on delivery");
        }

        if (payment.getPaymentStatus() != PaymentStatus.PENDING) {
            throw new IllegalStateException(
                    "Payment has already been processed");
        }

        if (success) {
            payment.setPaymentStatus(PaymentStatus.SUCCESS);
        } else {
            payment.setPaymentStatus(PaymentStatus.FAILED);
            inventoryClient.release(order.getId());
            order.setStatus(OrderStatus.CANCELLED);
            orderRepository.save(order);

            OrderStatusHistory history = new OrderStatusHistory();
            history.setOrder(order);
            history.setStatus(OrderStatus.CANCELLED);
            history.setChangedBy(userId);
            history.setRemarks("Order cancelled after payment failure");
            historyRepository.save(history);
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
                        new NoSuchElementException("Order not found"));

        if (!order.getUserId().equals(userId)) {
            throw new AccessDeniedException("Unauthorized access");
        }

        return paymentRepository.findByOrderId(orderId)
                .stream()
                .findFirst()
                .orElseThrow(() ->
                        new NoSuchElementException("Payment not found"));
    }


    @Transactional
    public Payment collectCodPayment(UUID paymentId, UUID riderId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new NoSuchElementException("Payment not found"));
        collectCodPayment(payment, riderId);
        return paymentRepository.save(payment);
    }

    private void collectCodPayment(Payment payment, UUID riderId) {

        if (payment.getPaymentMethod() != PaymentMethod.COD) {
            throw new IllegalStateException(
                    "This is not a COD payment");
        }

        if (payment.getPaymentStatus() != PaymentStatus.PENDING) {
            throw new IllegalStateException(
                    "Payment has already been processed");
        }

        RiderAssignment assignment = riderAssignmentRepository.findByOrderId(payment.getOrder().getId())
                .orElseThrow(() -> new IllegalStateException("Order is not assigned to a rider"));
        if (!assignment.getRiderId().equals(riderId)
                || (assignment.getStatus() != AssignmentStatus.PICKED_UP
                && assignment.getStatus() != AssignmentStatus.DELIVERED)) {
            throw new AccessDeniedException("Only the assigned rider can collect payment during delivery");
        }

        payment.setPaymentStatus(PaymentStatus.SUCCESS);
        payment.setTransactionReference(
                "COD-" + UUID.randomUUID()
        );
    }

    @Transactional
    public void refundSuccessfulPayment(UUID orderId) {
        List<Payment> payments = paymentRepository.findByOrderId(orderId);
        for (Payment payment : payments) {
            if (payment.getPaymentStatus() == PaymentStatus.SUCCESS) {
                payment.setPaymentStatus(PaymentStatus.REFUNDED);
                payment.setTransactionReference("MOCK-REFUND-" + UUID.randomUUID());
                paymentRepository.save(payment);
            }
        }
    }
}
