package com.darkstore.cart_order_service.service;

import com.darkstore.cart_order_service.entity.Cart;
import com.darkstore.cart_order_service.entity.CartItem;
import com.darkstore.cart_order_service.entity.Order;
import com.darkstore.cart_order_service.enums.CartStatus;
import com.darkstore.cart_order_service.integration.InventoryClient;
import com.darkstore.cart_order_service.repository.*;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CheckoutServiceTest {

    @Mock
    private CartService cartService;
    @Mock
    private CartRepository cartRepository;
    @Mock
    private CartItemRepository cartItemRepository;
    @Mock
    private OrderRepository orderRepository;
    @Mock
    private OrderItemRepository orderItemRepository;
    @Mock
    private OrderStatusHistoryRepository historyRepository;
    @Mock
    private InventoryClient inventoryClient;

    @AfterEach
    void clearTransactionSynchronization() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    void checkoutUsesInventoryPriceAndReservesTheOrderItems() {
        UUID userId = UUID.randomUUID();
        UUID storeId = UUID.randomUUID();
        UUID cartId = UUID.randomUUID();
        UUID productId = UUID.randomUUID();
        UUID orderId = UUID.randomUUID();

        Cart cart = new Cart();
        ReflectionTestUtils.setField(cart, "id", cartId);
        cart.setUserId(userId);
        cart.setStoreId(storeId);
        cart.setStatus(CartStatus.ACTIVE);

        CartItem cartItem = new CartItem();
        cartItem.setProductId(productId);
        cartItem.setProductName("Client supplied name");
        cartItem.setUnitPrice(new BigDecimal("100.00"));
        cartItem.setQuantity(2);

        when(cartService.getActiveCart(userId)).thenReturn(cart);
        when(cartItemRepository.findByCartId(cartId)).thenReturn(List.of(cartItem));
        when(inventoryClient.validateProducts(storeId, List.of(productId)))
                .thenReturn(List.of(new InventoryClient.AvailableProduct(
                        productId, "Catalog name", 5, new BigDecimal("4.25"))));
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> {
            Order order = invocation.getArgument(0);
            ReflectionTestUtils.setField(order, "id", orderId);
            return order;
        });
        when(inventoryClient.reserve(eq(orderId), eq(storeId), anyList()))
                .thenReturn(new InventoryClient.ReservationResponse(orderId, "CONFIRMED", List.of()));

        TransactionSynchronizationManager.initSynchronization();
        CheckoutService service = new CheckoutService(
                cartService,
                cartRepository,
                cartItemRepository,
                orderRepository,
                orderItemRepository,
                historyRepository,
                inventoryClient
        );

        Order order = service.checkout(userId);

        assertEquals(new BigDecimal("8.50"), order.getSubtotal());
        assertEquals("Catalog name", cartItem.getProductName());
        assertEquals(new BigDecimal("4.25"), cartItem.getUnitPrice());
        assertEquals(CartStatus.CHECKED_OUT, cart.getStatus());
        verify(inventoryClient).reserve(eq(orderId), eq(storeId), argThat(items ->
                items.size() == 1
                        && items.get(0).productId().equals(productId)
                        && items.get(0).quantity() == 2));
    }

    @Test
    void checkoutStopsWhenInventoryHasInsufficientStock() {
        UUID userId = UUID.randomUUID();
        UUID storeId = UUID.randomUUID();
        UUID cartId = UUID.randomUUID();
        UUID productId = UUID.randomUUID();
        Cart cart = new Cart();
        ReflectionTestUtils.setField(cart, "id", cartId);
        cart.setUserId(userId);
        cart.setStoreId(storeId);
        CartItem cartItem = new CartItem();
        cartItem.setProductId(productId);
        cartItem.setQuantity(2);

        when(cartService.getActiveCart(userId)).thenReturn(cart);
        when(cartItemRepository.findByCartId(cartId)).thenReturn(List.of(cartItem));
        when(inventoryClient.validateProducts(storeId, List.of(productId)))
                .thenReturn(List.of(new InventoryClient.AvailableProduct(
                        productId, "Catalog name", 1, BigDecimal.ONE)));

        CheckoutService service = new CheckoutService(
                cartService,
                cartRepository,
                cartItemRepository,
                orderRepository,
                orderItemRepository,
                historyRepository,
                inventoryClient
        );

        assertThrows(IllegalStateException.class, () -> service.checkout(userId));
        verifyNoInteractions(orderRepository, orderItemRepository, historyRepository, cartRepository);
        verify(inventoryClient, never()).reserve(any(), any(), anyList());
    }
}
