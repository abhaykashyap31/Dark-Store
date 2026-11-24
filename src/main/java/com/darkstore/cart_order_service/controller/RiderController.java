
package com.darkstore.cart_order_service.controller;

import com.darkstore.cart_order_service.dto.OrderItemResponse;
import com.darkstore.cart_order_service.dto.OrderResponse;
import com.darkstore.cart_order_service.entity.Order;
import com.darkstore.cart_order_service.entity.OrderItem;
import com.darkstore.cart_order_service.entity.RiderAssignment;
import com.darkstore.cart_order_service.service.OrderService;
import com.darkstore.cart_order_service.service.RiderAssignmentService;

import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/rider/orders")
@PreAuthorize("hasRole('RIDER')")
public class RiderController {

    private final RiderAssignmentService riderAssignmentService;
    private final OrderService orderService;

    public RiderController(
            RiderAssignmentService riderAssignmentService,
            OrderService orderService) {

        this.riderAssignmentService = riderAssignmentService;
        this.orderService = orderService;
    }

    // View available orders
    @GetMapping("/available")
    public List<OrderResponse> getAvailableOrders(
            @RequestHeader("X-STORE-ID") UUID storeId) {

        List<Order> orders =
                riderAssignmentService.getAvailableOrders(storeId);

        return orders.stream()
                .map(this::convertToResponse)
                .toList();
    }

    private OrderResponse convertToResponse(Order order) {

        List<OrderItem> items =
                orderService.getOrderItems(order.getId());

        List<OrderItemResponse> itemResponses = items.stream()
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
                itemResponses
        );
    }

    @PatchMapping("/{orderId}/accept")
    public RiderAssignment acceptOrder(
            @PathVariable UUID orderId,
            @RequestHeader("X-RIDER-ID") UUID riderId,
            @RequestHeader("X-STORE-ID") UUID storeId) {

        return riderAssignmentService.assignOrder(
                orderId,
                riderId,
                storeId
        );
    }

    @PatchMapping("/{orderId}/pickup")
    public RiderAssignment pickupOrder(
            @PathVariable UUID orderId,
            @RequestHeader("X-RIDER-ID") UUID riderId) {

        return riderAssignmentService.pickupOrder(orderId, riderId);
    }


        @PatchMapping("/{orderId}/deliver")
        public RiderAssignment deliverOrder(
                @PathVariable UUID orderId,
                @RequestHeader("X-RIDER-ID") UUID riderId) {

        return riderAssignmentService.deliverOrder(orderId, riderId);
        }

}
