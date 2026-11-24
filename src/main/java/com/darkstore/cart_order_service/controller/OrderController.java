
package com.darkstore.cart_order_service.controller;

import com.darkstore.cart_order_service.dto.*;
import com.darkstore.cart_order_service.entity.Order;
import com.darkstore.cart_order_service.entity.OrderItem;
import com.darkstore.cart_order_service.service.OrderService;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    // 1. Get all customer orders
    @GetMapping
    @PreAuthorize("hasRole('CUSTOMER')")
    public List<OrderResponse> getAllOrders(
            @RequestHeader("X-USER-ID") UUID userId
    ) {
        List<Order> orders = orderService.getAllOrders(userId);

        return orders.stream()
                .map(this::convertToResponse)
                .toList();
    }

    // 2. Get a particular order
    @GetMapping("/{orderId}")
    @PreAuthorize("hasRole('CUSTOMER')")
    public OrderResponse getOrder(
            @PathVariable UUID orderId,
            @RequestHeader("X-USER-ID") UUID userId
    ) {
        Order order = orderService.getOrder(orderId, userId);

        return convertToResponse(order);
    }

    // 3. Update order status
    @PatchMapping("/{orderId}/status")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public OrderResponse updateOrderStatus(
            @PathVariable UUID orderId,
            @Valid @RequestBody UpdateOrderStatusRequest request,
            @RequestHeader("X-USER-ID") UUID changedBy,
            @RequestHeader(name = "X-STORE-ID", required = false) UUID storeId
    ) {
        Order order = orderService.updateOrderStatus(
                orderId,
                request.getStatus(),
                changedBy,
                storeId
        );

        return convertToResponse(order);
    }

    // 4. Get order status history
    @GetMapping("/{orderId}/history")
    @PreAuthorize("hasRole('CUSTOMER')")
    public List<OrderStatusHistoryResponse> getOrderStatusHistory(
            @PathVariable UUID orderId,
            @RequestHeader("X-USER-ID") UUID userId
    ) {
        orderService.getOrder(orderId, userId);

        return orderService.getOrderStatusHistory(orderId)
                .stream()
                .map(history -> new OrderStatusHistoryResponse(
                        history.getStatus(),
                        history.getChangedBy(),
                        history.getRemarks(),
                        history.getChangedAt()
                ))
                .toList();
    }

    // 5. Cancel an order
    @PatchMapping("/{orderId}/cancel")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<OrderResponse> cancelOrder(
            @PathVariable UUID orderId,
            @RequestHeader("X-USER-ID") UUID userId
    ) {
        Order order = orderService.cancelOrder(orderId, userId);

        return ResponseEntity.ok(convertToResponse(order));
    }

    // Convert Order entity into response DTO
    private OrderResponse convertToResponse(Order order) {

        List<OrderItem> orderItems =
                orderService.getOrderItems(order.getId());

        List<OrderItemResponse> items = orderItems.stream()
                .map(item -> new OrderItemResponse(
                        item.getProductId(),
                        item.getProductName(),
                        item.getQuantity(),
                        item.getUnitPrice(),
                        item.getTotalPrice()
                ))
                .toList();

        return new OrderResponse(
                order.getId(),
                order.getUserId(),
                order.getStatus(),
                order.getSubtotal(),
                order.getDeliveryFee(),
                order.getTotalAmount(),
                order.getCreatedAt(),
                items
        );
    }

    
}
