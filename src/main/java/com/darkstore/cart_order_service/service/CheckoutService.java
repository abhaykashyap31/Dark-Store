
package com.darkstore.cart_order_service.service;

import com.darkstore.cart_order_service.entity.*;
import com.darkstore.cart_order_service.enums.*;

import com.darkstore.cart_order_service.repository.*;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Service
public class CheckoutService {

    private final CartService cartService;
    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final OrderStatusHistoryRepository historyRepository;

    public CheckoutService(
            CartService cartService,
            CartRepository cartRepository,
            CartItemRepository cartItemRepository,
            OrderRepository orderRepository,
            OrderItemRepository orderItemRepository,
            OrderStatusHistoryRepository historyRepository
    ) {
        this.cartService = cartService;
        this.cartRepository = cartRepository;
        this.cartItemRepository = cartItemRepository;
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.historyRepository = historyRepository;
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

        // 3. Calculate subtotal
        BigDecimal subtotal = cartItems.stream()
                .map(item -> item.getUnitPrice().multiply(
                        BigDecimal.valueOf(item.getQuantity())
                ))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Temporary delivery fee: zero
        BigDecimal deliveryFee = BigDecimal.ZERO;

        BigDecimal totalAmount = subtotal.add(deliveryFee);

        // 4. Create order
        Order order = new Order();

        order.setUserId(cart.getUserId());
        order.setStoreId(cart.getStoreId());
        order.setStatus(OrderStatus.PLACED);
        order.setSubtotal(subtotal);
        order.setDeliveryFee(deliveryFee);
        order.setTotalAmount(totalAmount);

        order = orderRepository.save(order);

        // 5. Copy cart products into order items
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
        }

        // 6. Record initial order status
        OrderStatusHistory history = new OrderStatusHistory();

        history.setOrder(order);
        history.setStatus(OrderStatus.PLACED);
        history.setChangedBy(userId);
        history.setRemarks("Order placed successfully");

        historyRepository.save(history);

        // 7. Mark cart as checked out
        cart.setStatus(CartStatus.CHECKED_OUT);

        cartRepository.save(cart);

        return order;
    }
}
