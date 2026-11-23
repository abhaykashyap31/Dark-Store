
package com.darkstore.cart_order_service.service;

import com.darkstore.cart_order_service.entity.Order;
import com.darkstore.cart_order_service.entity.OrderStatusHistory;
import com.darkstore.cart_order_service.entity.RiderAssignment;
import com.darkstore.cart_order_service.enums.AssignmentStatus;
import com.darkstore.cart_order_service.enums.OrderStatus;
import com.darkstore.cart_order_service.repository.OrderRepository;
import com.darkstore.cart_order_service.repository.OrderStatusHistoryRepository;
import com.darkstore.cart_order_service.repository.RiderAssignmentRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class RiderAssignmentService {

    private final OrderRepository orderRepository;
    private final RiderAssignmentRepository assignmentRepository;
    private final OrderStatusHistoryRepository historyRepository;

    public RiderAssignmentService(
            OrderRepository orderRepository,
            RiderAssignmentRepository assignmentRepository,
            OrderStatusHistoryRepository historyRepository) {

        this.orderRepository = orderRepository;
        this.assignmentRepository = assignmentRepository;
        this.historyRepository = historyRepository;
    }

    // View available orders
    public List<Order> getAvailableOrders(UUID storeId) {

        return orderRepository
                .findByStoreIdAndStatusOrderByCreatedAtAsc(
                        storeId,
                        OrderStatus.READY_FOR_PICKUP
                )
                .stream()
                .filter(order ->
                        !assignmentRepository.existsByOrderId(order.getId())
                )
                .toList();
    }

    // Assign order to rider
    @Transactional
    public RiderAssignment assignOrder(
            UUID orderId,
            UUID riderId,
            UUID riderStoreId) {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() ->
                        new IllegalArgumentException("Order not found"));

        if (!order.getStoreId().equals(riderStoreId)) {
            throw new IllegalArgumentException(
                    "Order does not belong to your store");
        }

        if (order.getStatus() != OrderStatus.READY_FOR_PICKUP) {
            throw new IllegalArgumentException(
                    "Order is not ready for pickup");
        }

        if (assignmentRepository.existsByOrderId(orderId)) {
            throw new IllegalArgumentException(
                    "Order is already assigned to a rider");
        }

        RiderAssignment assignment = new RiderAssignment();
        assignment.setOrder(order);
        assignment.setRiderId(riderId);

        return assignmentRepository.save(assignment);
    }

    // Rider picks up order
    @Transactional
    public RiderAssignment pickupOrder(
            UUID orderId,
            UUID riderId) {

        RiderAssignment assignment = assignmentRepository
                .findByOrderId(orderId)
                .orElseThrow(() ->
                        new IllegalArgumentException("Order is not assigned"));

        if (!assignment.getRiderId().equals(riderId)) {
            throw new IllegalArgumentException(
                    "This order is not assigned to you");
        }

        if (assignment.getStatus() != AssignmentStatus.ASSIGNED) {
            throw new IllegalArgumentException(
                    "Order cannot be picked up in its current state");
        }

        Order order = assignment.getOrder();

        if (order.getStatus() != OrderStatus.READY_FOR_PICKUP) {
            throw new IllegalArgumentException(
                    "Order is not ready for pickup");
        }

        assignment.setStatus(AssignmentStatus.PICKED_UP);
        assignment.setPickedUpAt(LocalDateTime.now());

        order.setStatus(OrderStatus.OUT_FOR_DELIVERY);

        OrderStatusHistory history = new OrderStatusHistory();
        history.setOrder(order);
        history.setStatus(OrderStatus.OUT_FOR_DELIVERY);
        history.setChangedBy(riderId);
        history.setRemarks(
                "Order picked up by rider and is out for delivery"
        );

        historyRepository.save(history);
        orderRepository.save(order);

        return assignmentRepository.save(assignment);
    }



        @Transactional
        public RiderAssignment deliverOrder(UUID orderId, UUID riderId) {

        RiderAssignment assignment = assignmentRepository
                .findByOrderId(orderId)
                .orElseThrow(() ->
                        new IllegalArgumentException("Order is not assigned"));

        // Verify the assigned rider
        if (!assignment.getRiderId().equals(riderId)) {
                throw new IllegalArgumentException(
                        "This order is not assigned to you");
        }

        // Verify assignment status
        if (assignment.getStatus() != AssignmentStatus.PICKED_UP) {
                throw new IllegalArgumentException(
                        "Order must be picked up before delivery");
        }

        Order order = assignment.getOrder();

        // Verify order status
        if (order.getStatus() != OrderStatus.OUT_FOR_DELIVERY) {
                throw new IllegalArgumentException(
                        "Order is not out for delivery");
        }

        // Update assignment
        assignment.setStatus(AssignmentStatus.DELIVERED);
        assignment.setDeliveredAt(LocalDateTime.now());

        // Update order
        order.setStatus(OrderStatus.DELIVERED);

        // Record order history
        OrderStatusHistory history = new OrderStatusHistory();
        history.setOrder(order);
        history.setStatus(OrderStatus.DELIVERED);
        history.setChangedBy(riderId);
        history.setRemarks("Order successfully delivered to customer");

        historyRepository.save(history);
        orderRepository.save(order);

        return assignmentRepository.save(assignment);
        }

}


