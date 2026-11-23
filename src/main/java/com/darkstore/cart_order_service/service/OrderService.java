
package com.darkstore.cart_order_service.service;

import com.darkstore.cart_order_service.entity.Order;
import com.darkstore.cart_order_service.entity.OrderItem;
import com.darkstore.cart_order_service.entity.OrderStatusHistory;

import com.darkstore.cart_order_service.enums.OrderStatus;

import com.darkstore.cart_order_service.repository.OrderRepository;
import com.darkstore.cart_order_service.repository.OrderItemRepository;
import com.darkstore.cart_order_service.repository.OrderStatusHistoryRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final OrderStatusHistoryRepository historyRepository;
    private final PaymentService paymentService;

    public OrderService(
            OrderRepository orderRepository,
            OrderItemRepository orderItemRepository,
            OrderStatusHistoryRepository historyRepository,
            PaymentService paymentService
    ) {
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.historyRepository = historyRepository;
        this.paymentService = paymentService;
    }

    // 1. Get a particular order
    @Transactional(readOnly = true)
    public Order getOrder(UUID orderId, UUID userId) {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() ->
                        new IllegalArgumentException("Order not found")
                );

        if (!order.getUserId().equals(userId)) {
            throw new IllegalArgumentException(
                    "You cannot access this order"
            );
        }

        return order;
    }

    // 2. Get products belonging to an order
    @Transactional(readOnly = true)
    public List<OrderItem> getOrderItems(UUID orderId) {

        return orderItemRepository.findByOrderId(orderId);
    }

    // 3. Get all orders belonging to a customer
    @Transactional(readOnly = true)
    public List<Order> getAllOrders(UUID userId) {

        return orderRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    // 4. Update order status with transition validation
    @Transactional
    public Order updateOrderStatus(
            UUID orderId,
            OrderStatus newStatus,
            UUID changedBy
    ) {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() ->
                        new IllegalArgumentException("Order not found")
                );

        OrderStatus currentStatus = order.getStatus();

        boolean validTransition = switch (currentStatus) {

            case PLACED ->
                    newStatus == OrderStatus.CONFIRMED;

            case CONFIRMED ->
                    newStatus == OrderStatus.PREPARING;

            case PREPARING ->
                    newStatus == OrderStatus.READY_FOR_PICKUP;

            case READY_FOR_PICKUP ->
                    newStatus == OrderStatus.OUT_FOR_DELIVERY;

            case OUT_FOR_DELIVERY ->
                    newStatus == OrderStatus.DELIVERED;

            default -> false;
        };

        if (!validTransition) {
            throw new IllegalArgumentException(
                    "Invalid order status transition: "
                    + currentStatus + " to " + newStatus
            );
        }

        order.setStatus(newStatus);
        orderRepository.save(order);

        // Record status history
        OrderStatusHistory history = new OrderStatusHistory();

        history.setOrder(order);
        history.setStatus(newStatus);
        history.setChangedBy(changedBy);
        history.setRemarks(
                "Order status updated from "
                + currentStatus + " to " + newStatus
        );

        historyRepository.save(history);

        return order;
    }

    // 5. Get complete status history of an order
    @Transactional(readOnly = true)
    public List<OrderStatusHistory> getOrderStatusHistory(UUID orderId) {

        return historyRepository
                .findByOrderIdOrderByChangedAtAsc(orderId);
    }

    // 6. Cancel order and initiate mock refund
    @Transactional
    public Order cancelOrder(UUID orderId, UUID userId) {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() ->
                        new IllegalArgumentException("Order not found")
                );

        // Check order ownership
        if (!order.getUserId().equals(userId)) {
            throw new IllegalArgumentException(
                    "You cannot cancel this order"
            );
        }

        // Cancellation allowed only before preparation
        if (order.getStatus() != OrderStatus.PLACED &&
                order.getStatus() != OrderStatus.CONFIRMED) {

            throw new IllegalArgumentException(
                    "This order cannot be cancelled"
            );
        }

        // Update order status
        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        // Record cancellation history
        OrderStatusHistory history = new OrderStatusHistory();

        history.setOrder(order);
        history.setStatus(OrderStatus.CANCELLED);
        history.setChangedBy(userId);
        history.setRemarks("Order cancelled by customer");

        historyRepository.save(history);

        // Handle refund if payment was successful
        paymentService.refundSuccessfulPayment(orderId);

        return order;
    }

    @Transactional(readOnly = true)
    public List<Order> getOrdersByStatus(OrderStatus status) {
        return orderRepository.findByStatusOrderByCreatedAtAsc(status);
    }

    @Transactional(readOnly = true)
    public List<Order> getOrdersByStoreAndStatus(
            UUID storeId,
            OrderStatus status) {

        return orderRepository
                .findByStoreIdAndStatusOrderByCreatedAtAsc(
                        storeId, status);
    }
}
