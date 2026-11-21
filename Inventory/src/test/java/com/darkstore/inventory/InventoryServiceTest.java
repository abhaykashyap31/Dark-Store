package com.darkstore.inventory;

import com.darkstore.inventory.domain.StoreInventory;
import com.darkstore.inventory.dto.Dtos.*;
import com.darkstore.inventory.repository.CategoryRepository;
import com.darkstore.inventory.repository.ProductRepository;
import com.darkstore.inventory.repository.StoreInventoryRepository;
import com.darkstore.inventory.service.InventoryService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class InventoryServiceTest {
    @Autowired
    private InventoryService inventory;
    @Autowired
    private CategoryRepository categories;
    @Autowired
    private ProductRepository products;
    @Autowired
    private StoreInventoryRepository storeInventory;
    @Autowired
    private MockMvc mockMvc;

    @Test
    void reserveIsIdempotentAndReleaseRestoresStock() {
        UUID storeId = UUID.randomUUID();
        UUID orderId = UUID.randomUUID();
        var product = inventory.createProduct(new ProductRequest(
                "Milk", "Fresh milk", "MILK-1", null, true));

        inventory.upsertStock(new StockRequest(storeId, product.getId(),
                new BigDecimal("4.50"), 10, 2));

        ReserveRequest request = new ReserveRequest(orderId, storeId,
                List.of(new ReservationItem(product.getId(), 3)));
        ReserveResponse first = inventory.reserve(request);
        ReserveResponse repeated = inventory.reserve(request);

        assertEquals("CONFIRMED", first.status());
        assertEquals("CONFIRMED", repeated.status());
        assertEquals(7, inventory.getStock(storeId, product.getId()).getAvailable());

        ReserveResponse released = inventory.release(orderId);
        assertEquals("RELEASED", released.status());
        assertEquals(10, inventory.getStock(storeId, product.getId()).getAvailable());
    }

    @Test
    void confirmConsumesReservedStock() {
        UUID storeId = UUID.randomUUID();
        UUID orderId = UUID.randomUUID();
        var product = inventory.createProduct(new ProductRequest(
                "Bread", "Whole wheat", "BREAD-1", null, true));
        inventory.upsertStock(new StockRequest(storeId, product.getId(),
                new BigDecimal("3.25"), 5, 1));
        inventory.reserve(new ReserveRequest(orderId, storeId,
                List.of(new ReservationItem(product.getId(), 2))));

        inventory.confirm(orderId);
        StoreInventory stock = inventory.getStock(storeId, product.getId());

        assertEquals(3, stock.getOnHand());
        assertEquals(0, stock.getReserved());
    }

    @Test
    void failedReservationDoesNotPartiallyReserve() {
        UUID storeId = UUID.randomUUID();
        UUID orderId = UUID.randomUUID();
        var first = inventory.createProduct(new ProductRequest("A", null, "A", null, true));
        var second = inventory.createProduct(new ProductRequest("B", null, "B", null, true));
        inventory.upsertStock(new StockRequest(storeId, first.getId(), BigDecimal.ONE, 5, 1));
        inventory.upsertStock(new StockRequest(storeId, second.getId(), BigDecimal.ONE, 1, 1));

        ReserveResponse response = inventory.reserve(new ReserveRequest(orderId, storeId,
                List.of(new ReservationItem(first.getId(), 2),
                        new ReservationItem(second.getId(), 2))));

        assertEquals("FAILED", response.status());
        assertEquals(5, inventory.getStock(storeId, first.getId()).getAvailable());
        assertEquals(1, inventory.getStock(storeId, second.getId()).getAvailable());
    }

    @Test
    void categoryAndProductSupportCrudAndProtectReferencedCategories() {
        var category = inventory.createCategory(new CategoryRequest("Snacks", "Packaged food"));
        assertEquals("snacks", category.getSlug());

        var updatedCategory = inventory.updateCategory(category.getId(),
                new CategoryRequest("Pantry", "Shelf-stable food"));
        assertEquals("pantry", updatedCategory.getSlug());

        var product = inventory.createProduct(new ProductRequest(
                "Rice", "Long grain", "RICE-CRUD", updatedCategory.getId(), true));
        assertEquals(product.getId(), inventory.getProduct(product.getId()).getId());
        assertThrows(InventoryService.ResourceConflictException.class,
                () -> inventory.deleteCategory(updatedCategory.getId()));

        inventory.deleteProduct(product.getId());
        assertThrows(InventoryService.ResourceNotFoundException.class,
                () -> inventory.getProduct(product.getId()));
        inventory.deleteCategory(updatedCategory.getId());
        assertThrows(InventoryService.ResourceNotFoundException.class,
                () -> inventory.getCategory(updatedCategory.getId()));
    }

    @Test
    void inventoryListWithoutStoreFilterReturnsAllStock() {
        UUID storeId = UUID.randomUUID();
        var product = inventory.createProduct(new ProductRequest("Juice", null, "JUICE-LIST", null, true));
        inventory.upsertStock(new StockRequest(storeId, product.getId(), BigDecimal.ONE, 8, 1));

        assertTrue(inventory.listStock(null).stream()
                .anyMatch(stock -> stock.getStoreId().equals(storeId)
                        && stock.getProductId().equals(product.getId())));
    }

    @Test
    void catalogHttpRoutesSupportCrudAndProtectReferencedResources() throws Exception {
        String suffix = UUID.randomUUID().toString();
        String categoryName = "HTTP category " + suffix;
        String categoryBody = """
                {"name":"%s","description":"API test category","parentId":null,"active":true}
                """.formatted(categoryName);

        String categoryResponse = mockMvc.perform(post("/categories")
                        .contentType(APPLICATION_JSON).content(categoryBody))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        UUID categoryId = UUID.fromString(
                new com.fasterxml.jackson.databind.ObjectMapper().readTree(categoryResponse).get("id").asText());

        mockMvc.perform(get("/categories/{id}", categoryId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.slug").value(categoryName.toLowerCase().replace(' ', '-')));

        mockMvc.perform(put("/categories/{id}", categoryId)
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {"name":"%s","description":"Updated API test category","parentId":null,"active":true}
                                """.formatted(categoryName + " Updated")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value(categoryName + " Updated"));

        String sku = "HTTP-" + suffix;
        String productBody = """
                {"name":"API test product","description":null,"sku":"%s","categoryId":"%s",
                 "imageUrl":null,"basePrice":1.25,"active":true}
                """.formatted(sku, categoryId);
        String productResponse = mockMvc.perform(post("/products")
                        .contentType(APPLICATION_JSON).content(productBody))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        UUID productId = UUID.fromString(
                new com.fasterxml.jackson.databind.ObjectMapper().readTree(productResponse).get("id").asText());

        mockMvc.perform(get("/products/{id}", productId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sku").value(sku));
        mockMvc.perform(put("/products/{id}", productId)
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {"name":"Updated API product","description":null,"sku":"%s","categoryId":"%s",
                                 "imageUrl":null,"basePrice":2.50,"active":true}
                                """.formatted(sku, categoryId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Updated API product"));

        mockMvc.perform(delete("/categories/{id}", categoryId))
                .andExpect(status().isConflict());
        mockMvc.perform(delete("/products/{id}", productId))
                .andExpect(status().isNoContent());
        mockMvc.perform(delete("/categories/{id}", categoryId))
                .andExpect(status().isNoContent());
        mockMvc.perform(get("/categories/{id}", categoryId))
                .andExpect(status().isNotFound());
    }
}
