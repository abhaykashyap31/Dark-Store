package com.darkstore.cart_order_service.repository;

import com.darkstore.cart_order_service.entity.OrderStatusHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface OrderStatusHistoryRepository
        extends JpaRepository<OrderStatusHistory, UUID> {

    List<OrderStatusHistory> findByOrderIdOrderByChangedAtAsc(UUID orderId);
}