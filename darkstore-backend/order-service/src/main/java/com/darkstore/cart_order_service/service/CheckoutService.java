
package com.darkstore.cart_order_service.service;

import com.darkstore.cart_order_service.entity.*;
import com.darkstore.cart_order_service.enums.*;

import com.darkstore.cart_order_service.repository.*;
import com.darkstore.cart_order_service.integration.InventoryIntegrationException;
import com.darkstore.cart_order_service.integration.InventoryClient;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class CheckoutService {

    private static final Logger log = LoggerFactory.getLogger(CheckoutService.class);

    private final CartService cartService;
    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final OrderStatusHistoryRepository historyRepository;
    private final InventoryClient inventoryClient;

    public CheckoutService(
            CartService cartService,
            CartRepository cartRepository,
            CartItemRepository cartItemRepository,
            OrderRepository orderRepository,
            OrderItemRepository orderItemRepository,
            OrderStatusHistoryRepository historyRepository,
            InventoryClient inventoryClient
    ) {
        this.cartService = cartService;
        this.cartRepository = cartRepository;
        this.cartItemRepository = cartItemRepository;
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.historyRepository = historyRepository;
        this.inventoryClient = inventoryClient;
    }

    @Transactional
    public Order checkout(UUID userId) {

        // 1. Get customer's active cart
        Cart cart = cartService.getActiveCart(userId);

        // 2. Get cart products
        List<CartItem> cartItems =
                cartItemRepository.findByCartId(cart.getId());

        if (cartItems.isEmpty()) {
            throw new IllegalStateException(
                    "Cannot checkout an empty cart"
            );
        }

        List<UUID> productIds = cartItems.stream()
                .map(CartItem::getProductId)
                .distinct()
                .toList();
        Map<UUID, InventoryClient.AvailableProduct> productsById =
                inventoryClient.validateProducts(cart.getStoreId(), productIds).stream()
                        .collect(Collectors.toMap(
                                InventoryClient.AvailableProduct::productId,
                                Function.identity()
                        ));

        for (CartItem cartItem : cartItems) {
            InventoryClient.AvailableProduct product = productsById.get(cartItem.getProductId());
            if (product == null) {
                throw new InventoryIntegrationException(502,
                        "Inventory did not return product " + cartItem.getProductId(), null);
            }
            if (product.available() < cartItem.getQuantity()) {
                throw new IllegalStateException(
                        "Insufficient stock for product " + product.productId()
                                + "; available=" + product.available());
            }
            cartItem.setProductName(product.name());
            cartItem.setUnitPrice(product.price());
            cartItemRepository.save(cartItem);
        }

        // Calculate subtotal from the current inventory prices, not client-provided cart values.
        BigDecimal subtotal = cartItems.stream()
                .map(item -> item.getUnitPrice().multiply(
                        BigDecimal.valueOf(item.getQuantity())
                ))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Temporary delivery fee: zero
        BigDecimal deliveryFee = BigDecimal.ZERO;

        BigDecimal totalAmount = subtotal.add(deliveryFee);

        // Create the order before reserving so its ID can be used as the inventory reference.
        Order order = new Order();

        order.setUserId(cart.getUserId());
        order.setStoreId(cart.getStoreId());
        order.setStatus(OrderStatus.PLACED);
        order.setSubtotal(subtotal);
        order.setDeliveryFee(deliveryFee);
        order.setTotalAmount(totalAmount);

        order = orderRepository.save(order);

        // Copy validated cart products into order items.
        List<InventoryClient.ReservationItem> reservationItems = new ArrayList<>();
        for (CartItem cartItem : cartItems) {

            OrderItem orderItem = new OrderItem();

            orderItem.setOrder(order);
            orderItem.setProductId(cartItem.getProductId());
            orderItem.setProductName(cartItem.getProductName());
            orderItem.setQuantity(cartItem.getQuantity());
            orderItem.setUnitPrice(cartItem.getUnitPrice());

            BigDecimal itemTotal =
                    cartItem.getUnitPrice().multiply(
                            BigDecimal.valueOf(cartItem.getQuantity())
                    );

            orderItem.setTotalPrice(itemTotal);

            orderItemRepository.save(orderItem);
            reservationItems.add(new InventoryClient.ReservationItem(
                    cartItem.getProductId(), cartItem.getQuantity()));
        }

        // Record initial order status.
        OrderStatusHistory history = new OrderStatusHistory();

        history.setOrder(order);
        history.setStatus(OrderStatus.PLACED);
        history.setChangedBy(userId);
        history.setRemarks("Order placed successfully");

        historyRepository.save(history);

        // Mark cart as checked out.
        cart.setStatus(CartStatus.CHECKED_OUT);

        cartRepository.save(cart);

        // Reserve stock after preparing all local records so a rejected reservation rolls back checkout.
        InventoryClient.ReservationResponse reservation = inventoryClient.reserve(
                order.getId(), cart.getStoreId(), reservationItems);
        if (!"CONFIRMED".equals(reservation.status())) {
            throw new InventoryIntegrationException(409,
                    "Inventory could not reserve all items for order " + order.getId(), null);
        }
        UUID reservedOrderId = order.getId();
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCompletion(int status) {
                if (status == STATUS_ROLLED_BACK) {
                    try {
                        inventoryClient.release(reservedOrderId);
                    } catch (InventoryIntegrationException ex) {
                        log.error("Failed to release inventory for rolled-back order {}", reservedOrderId, ex);
                    }
                }
            }
        });

        return order;
    }
}
