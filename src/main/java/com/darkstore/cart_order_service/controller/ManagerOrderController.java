
package com.darkstore.cart_order_service.controller;

import com.darkstore.cart_order_service.dto.OrderItemResponse;
import com.darkstore.cart_order_service.dto.OrderResponse;
import com.darkstore.cart_order_service.dto.UpdateOrderStatusRequest;
import com.darkstore.cart_order_service.entity.Order;
import com.darkstore.cart_order_service.entity.OrderItem;
import com.darkstore.cart_order_service.enums.OrderStatus;
import com.darkstore.cart_order_service.service.OrderService;

import org.springframework.web.bind.annotation.*;

import java.util.UUID;
import java.util.List;

@RestController
@RequestMapping("/api/v1/manager/orders")
public class ManagerOrderController {

    private final OrderService orderService;

    public ManagerOrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    // View orders by status
    @GetMapping
    public List<OrderResponse> getOrdersByStatus(
            @RequestHeader("X-STORE-ID") UUID storeId,
            @RequestParam OrderStatus status) {

        List<Order> orders =
                orderService.getOrdersByStoreAndStatus(storeId, status);

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


    @PatchMapping("/{orderId}/status")
    public OrderResponse updateOrderStatus(
            @PathVariable UUID orderId,
            @RequestBody UpdateOrderStatusRequest request) {

        Order updatedOrder = orderService.updateOrderStatus(
                orderId,
                request.getStatus(),
                request.getChangedBy()
        );

        return convertToResponse(updatedOrder);
    }

}
