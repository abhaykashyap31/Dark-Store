package com.darkstore.cart_order_service.repository;

import com.darkstore.cart_order_service.entity.Order;
import com.darkstore.cart_order_service.enums.OrderStatus;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface OrderRepository extends JpaRepository<Order, UUID> {

    List<Order> findByUserIdOrderByCreatedAtDesc(UUID userId);
    List<Order> findByStatusOrderByCreatedAtAsc(OrderStatus status);
    List<Order> findByStoreIdAndStatusOrderByCreatedAtAsc(
        UUID storeId,
        OrderStatus status
);
}