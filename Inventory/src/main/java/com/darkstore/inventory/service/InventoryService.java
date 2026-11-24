package com.darkstore.inventory.service;

import com.darkstore.inventory.domain.*;
import com.darkstore.inventory.dto.Dtos.*;
import com.darkstore.inventory.dto.Dtos;
import com.darkstore.inventory.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class InventoryService {
    private final CategoryRepository categories;
    private final ProductRepository products;
    private final StoreInventoryRepository inventory;
    private final StockReservationRepository reservations;
    private final StockMovementRepository movements;
    private final ReservationItemRepository reservationItems;

    public InventoryService(CategoryRepository categories, ProductRepository products,
                            StoreInventoryRepository inventory,
                            StockReservationRepository reservations,
                            StockMovementRepository movements,
                            ReservationItemRepository reservationItems) {
        this.categories = categories;
        this.products = products;
        this.inventory = inventory;
        this.reservations = reservations;
        this.movements = movements;
        this.reservationItems = reservationItems;
    }

    public Category createCategory(CategoryRequest request) {
        Category category = new Category();
        applyCategory(category, request);
        return categories.save(category);
    }

    public Category getCategory(UUID id) {
        return categories.findById(id).orElseThrow(() -> new ResourceNotFoundException("Category", id));
    }

    public List<Category> listCategories() {
        return categories.findAll();
    }

    public Category updateCategory(UUID id, CategoryRequest request) {
        Category category = getCategory(id);
        applyCategory(category, request);
        return categories.save(category);
    }

    public void deleteCategory(UUID id) {
        Category category = getCategory(id);
        if (products.existsByCategoryId(id) || categories.existsByParentId(id)) {
            throw new ResourceConflictException("Category is referenced by products or child categories");
        }
        categories.delete(category);
    }

    private void applyCategory(Category category, CategoryRequest request) {
        if (request.parentId() != null) {
            if (request.parentId().equals(category.getId())) {
                throw new IllegalArgumentException("A category cannot be its own parent");
            }
            categories.findById(request.parentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Parent category", request.parentId()));
        }
        if (category.getId() == null) {
            if (categories.existsByName(request.name())) {
                throw new ResourceConflictException("Category name already exists: " + request.name());
            }
        } else if (categories.existsByNameAndIdNot(request.name(), category.getId())) {
            throw new ResourceConflictException("Category name already exists: " + request.name());
        }
        String slug = toSlug(request.name());
        boolean slugUsed = category.getId() == null
                ? categories.existsBySlug(slug)
                : categories.existsBySlugAndIdNot(slug, category.getId());
        if (slugUsed) {
            throw new ResourceConflictException("Category slug already exists: " + slug);
        }
        category.setName(request.name());
        category.setDescription(request.description());
        category.setParentId(request.parentId());
        category.setSlug(slug);
        category.setActive(request.active());
        category.setUpdatedAt(Instant.now());
    }

    public Product createProduct(ProductRequest request) {
        Product product = new Product();
        applyProduct(product, request);
        return products.save(product);
    }

    public Product updateProduct(UUID id, ProductRequest request) {
        Product product = getProduct(id);
        applyProduct(product, request);
        return products.save(product);
    }

    public void deleteProduct(UUID id) {
        Product product = getProduct(id);
        if (inventory.existsByProductId(id) || reservationItems.existsByProductId(id)
                || movements.existsByStoreInventory_ProductId(id)) {
            throw new ResourceConflictException("Product has inventory or stock history and cannot be deleted");
        }
        products.delete(product);
    }

    public Product getProduct(UUID id) {
        return products.findById(id).orElseThrow(() -> new ResourceNotFoundException("Product", id));
    }

    public List<Product> listProducts() {
        return products.findAll();
    }

    private void applyProduct(Product product, ProductRequest request) {
        if (request.categoryId() != null) {
            categories.findById(request.categoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", request.categoryId()));
        }
        if (product.getId() == null) {
            if (products.existsBySku(request.sku())) {
                throw new ResourceConflictException("Product SKU already exists: " + request.sku());
            }
        } else if (products.existsBySkuAndIdNot(request.sku(), product.getId())) {
            throw new ResourceConflictException("Product SKU already exists: " + request.sku());
        }
        product.setName(request.name());
        product.setDescription(request.description());
        product.setSku(request.sku());
        product.setCategoryId(request.categoryId());
        product.setImageUrl(request.imageUrl());
        product.setBasePrice(request.basePrice() == null ? java.math.BigDecimal.ZERO : request.basePrice());
        product.setActive(request.active());
        product.setUpdatedAt(Instant.now());
        if (product.getCreatedAt() == null) {
            product.setCreatedAt(Instant.now());
        }
    }

    @Transactional
    public StoreInventory upsertStock(StockRequest request) {
        if (request.onHand() < 0 || request.lowStockThreshold() < 0) {
            throw new IllegalArgumentException("Stock quantities cannot be negative");
        }
        if (request.price() == null || request.price().signum() < 0) {
            throw new IllegalArgumentException("Price cannot be negative");
        }
        products.findById(request.productId())
                .orElseThrow(() -> new ResourceNotFoundException("Product", request.productId()));
        StoreInventory record = inventory.findForUpdateByStoreIdAndProductId(request.storeId(), request.productId())
                .orElseGet(StoreInventory::new);
        if (request.onHand() < record.getReserved()) {
            throw new InsufficientStockException(request.productId(), request.onHand() - record.getReserved());
        }
        record.setStoreId(request.storeId());
        record.setProductId(request.productId());
        record.setOnHand(request.onHand());
        record.setLowStockThreshold(request.lowStockThreshold());
        record.setPrice(request.price());
        record.setUpdatedAt(Instant.now());
        return inventory.save(record);
    }

    public List<StoreInventory> listStock(UUID storeId) {
        return storeId == null ? inventory.findAll() : inventory.findByStoreId(storeId);
    }

    public StoreInventory getStock(UUID storeId, UUID productId) {
        return inventory.findByStoreIdAndProductId(storeId, productId)
                .orElseThrow(() -> new ResourceNotFoundException("Store inventory",
                        storeId + "/" + productId));
    }

    public List<StoreInventory> lowStock(UUID storeId) {
        List<StoreInventory> records = storeId == null ? inventory.findAll() : inventory.findByStoreId(storeId);
        List<StoreInventory> low = new ArrayList<>();
        for (StoreInventory record : records) {
            if (record.getAvailable() <= record.getLowStockThreshold()) {
                low.add(record);
            }
        }
        return low;
    }

    @Transactional
    public StoreInventory adjustStock(StockAdjustment request) {
        if (request.quantityChange() == 0) {
            throw new IllegalArgumentException("quantityChange must not be zero");
        }
        StoreInventory record = inventory.findForUpdateByStoreIdAndProductId(request.storeId(), request.productId())
                .orElseThrow(() -> new ResourceNotFoundException("Store inventory",
                        request.storeId() + "/" + request.productId()));
        int next = record.getOnHand() + request.quantityChange();
        if (next < record.getReserved()) {
            throw new InsufficientStockException(request.productId(), next - record.getReserved());
        }
        record.setOnHand(next);
        record.setUpdatedAt(Instant.now());
        inventory.save(record);
        recordMovement(record, request.quantityChange(), "ADJUSTMENT", request.reason(),
                "ADJUSTMENT", request.referenceId());
        return record;
    }

    @Transactional
    public ReserveResponse reserve(ReserveRequest request) {
        if (request.items() == null || request.items().isEmpty()) {
            throw new IllegalArgumentException("items must not be empty");
        }

        Map<UUID, Integer> quantities = new LinkedHashMap<>();
        for (com.darkstore.inventory.dto.Dtos.ReservationItem item : request.items()) {
            if (item.quantity() <= 0) {
                throw new IllegalArgumentException("Reservation quantities must be positive");
            }
            quantities.merge(item.productId(), item.quantity(), Integer::sum);
        }

        List<ReservationItemResult> failed = new ArrayList<>();
        StockReservation existingReservation = reservations.findByOrderIdAndStoreId(
                request.orderId(), request.storeId()).orElse(null);
        Map<UUID, Integer> existingQuantities = existingReservation == null
                ? Map.of()
                : quantitiesFor(existingReservation);
        if (existingReservation != null) {
            if (existingReservation.getStatus() == StockReservation.ReservationStatus.RELEASED
                    || !existingQuantities.equals(quantities)) {
                for (Map.Entry<UUID, Integer> entry : quantities.entrySet()) {
                    failed.add(new ReservationItemResult(entry.getKey(), entry.getValue(), "FAILED", null));
                }
            }
        } else {
            for (Map.Entry<UUID, Integer> entry : quantities.entrySet()) {
                UUID productId = entry.getKey();
                int quantity = entry.getValue();
                StoreInventory record = inventory.findForUpdateByStoreIdAndProductId(request.storeId(), productId)
                        .orElseThrow(() -> new ResourceNotFoundException("Store inventory",
                                request.storeId() + "/" + productId));
                if (record.getAvailable() < quantity) {
                    failed.add(new ReservationItemResult(productId, quantity, "FAILED",
                            record.getAvailable()));
                }
            }
        }
        if (!failed.isEmpty()) {
            return new ReserveResponse(request.orderId(), "FAILED", failed);
        }

        List<ReservationItemResult> results = new ArrayList<>();
        for (Map.Entry<UUID, Integer> entry : quantities.entrySet()) {
            UUID productId = entry.getKey();
            int quantity = entry.getValue();
            StoreInventory record = inventory.findForUpdateByStoreIdAndProductId(request.storeId(), productId)
                    .orElseThrow(() -> new ResourceNotFoundException("Store inventory",
                            request.storeId() + "/" + productId));
            if (existingReservation != null) {
                results.add(new ReservationItemResult(productId, quantity,
                        existingReservation.getStatus().name(), record.getAvailable()));
                continue;
            }
            record.setReserved(record.getReserved() + quantity);
            record.setUpdatedAt(Instant.now());
            inventory.save(record);

            recordMovement(record, -quantity, "RESERVE", "RESERVE", "ORDER", request.orderId());
            results.add(new ReservationItemResult(productId, quantity, "RESERVED",
                    record.getAvailable()));
        }
        if (existingReservation == null) {
            StockReservation reservation = new StockReservation();
            reservation.setOrderId(request.orderId());
            reservation.setStoreId(request.storeId());
            reservation.setStatus(StockReservation.ReservationStatus.RESERVED);
            reservation = reservations.save(reservation);
            for (Map.Entry<UUID, Integer> entry : quantities.entrySet()) {
                com.darkstore.inventory.domain.ReservationItem reservationItem =
                        new com.darkstore.inventory.domain.ReservationItem();
                reservationItem.setReservationId(reservation.getId());
                reservationItem.setProductId(entry.getKey());
                reservationItem.setQuantity(entry.getValue());
                reservationItems.save(reservationItem);
            }
        }
        String status = existingReservation == null
                ? StockReservation.ReservationStatus.RESERVED.name()
                : existingReservation.getStatus().name();
        return new ReserveResponse(request.orderId(), status, results);
    }

    @Transactional
    public ReserveResponse release(UUID orderId) {
        List<StockReservation> orderReservations = reservations.findByOrderId(orderId);
        if (orderReservations.isEmpty()) {
            throw new ResourceNotFoundException("Reservations for order", orderId);
        }
        List<ReservationItemResult> results = new ArrayList<>();
        for (StockReservation reservation : orderReservations) {
            if (reservation.getStatus() == StockReservation.ReservationStatus.CONFIRMED) {
                throw new IllegalStateException("Confirmed reservations cannot be released");
            }
            for (com.darkstore.inventory.domain.ReservationItem item : reservationItems.findByReservationId(reservation.getId())) {
                StoreInventory record = inventory.findForUpdateByStoreIdAndProductId(
                                reservation.getStoreId(), item.getProductId())
                        .orElseThrow(() -> new ResourceNotFoundException("Store inventory",
                                reservation.getStoreId() + "/" + item.getProductId()));
                if (reservation.getStatus() == StockReservation.ReservationStatus.RESERVED) {
                    record.setReserved(Math.max(0, record.getReserved() - item.getQuantity()));
                    record.setUpdatedAt(Instant.now());
                    inventory.save(record);
                    recordMovement(record, item.getQuantity(), "RELEASE", "RELEASE", "ORDER", orderId);
                }
                results.add(new ReservationItemResult(item.getProductId(), item.getQuantity(),
                        "RELEASED", record.getAvailable()));
            }
            if (reservation.getStatus() == StockReservation.ReservationStatus.RESERVED) {
                reservation.setStatus(StockReservation.ReservationStatus.RELEASED);
                reservation.setUpdatedAt(Instant.now());
                reservations.save(reservation);
            }
        }
        return new ReserveResponse(orderId, "RELEASED", results);
    }

    @Transactional
    public ReserveResponse confirm(UUID orderId) {
        List<StockReservation> orderReservations = reservations.findByOrderId(orderId);
        if (orderReservations.isEmpty()) {
            throw new ResourceNotFoundException("Reservations for order", orderId);
        }
        List<ReservationItemResult> results = new ArrayList<>();
        for (StockReservation reservation : orderReservations) {
            if (reservation.getStatus() == StockReservation.ReservationStatus.RELEASED) {
                throw new IllegalStateException("Released reservations cannot be confirmed");
            }
            for (com.darkstore.inventory.domain.ReservationItem item : reservationItems.findByReservationId(reservation.getId())) {
                StoreInventory record = inventory.findForUpdateByStoreIdAndProductId(
                                reservation.getStoreId(), item.getProductId())
                        .orElseThrow(() -> new ResourceNotFoundException("Store inventory",
                                reservation.getStoreId() + "/" + item.getProductId()));
                if (reservation.getStatus() == StockReservation.ReservationStatus.RESERVED) {
                    record.setReserved(Math.max(0, record.getReserved() - item.getQuantity()));
                    record.setOnHand(Math.max(0, record.getOnHand() - item.getQuantity()));
                    record.setUpdatedAt(Instant.now());
                    inventory.save(record);
                    recordMovement(record, -item.getQuantity(), "CONFIRM", "CONFIRM", "ORDER", orderId);
                }
                results.add(new ReservationItemResult(item.getProductId(), item.getQuantity(),
                        "CONFIRMED", record.getAvailable()));
            }
            if (reservation.getStatus() == StockReservation.ReservationStatus.RESERVED) {
                reservation.setStatus(StockReservation.ReservationStatus.CONFIRMED);
                reservation.setUpdatedAt(Instant.now());
                reservations.save(reservation);
            }
        }
        return new ReserveResponse(orderId, "CONFIRMED", results);
    }

    private Map<UUID, Integer> quantitiesFor(StockReservation reservation) {
        Map<UUID, Integer> quantities = new LinkedHashMap<>();
        for (com.darkstore.inventory.domain.ReservationItem item : reservationItems.findByReservationId(reservation.getId())) {
            quantities.put(item.getProductId(), item.getQuantity());
        }
        return quantities;
    }

    public ValidateResponse validate(UUID storeId, List<UUID> productIds) {
        List<ValidateItem> items = new ArrayList<>();
        for (UUID productId : productIds) {
            Product product = products.findById(productId)
                    .orElseThrow(() -> new ResourceNotFoundException("Product", productId));
            StoreInventory stock = inventory.findByStoreIdAndProductId(storeId, productId)
                    .orElseThrow(() -> new ResourceNotFoundException("Store inventory",
                            storeId + "/" + productId));
            items.add(new ValidateItem(productId, product.getName(), stock.getAvailable(), stock.getPrice()));
        }
        return new ValidateResponse(storeId, items);
    }

    public List<StockMovement> movements(UUID storeId, UUID productId) {
        return movements.findByStoreInventory_StoreIdAndStoreInventory_ProductIdOrderByCreatedAtDesc(
                storeId, productId);
    }

    private void recordMovement(StoreInventory record, int quantityChange, String type, String reason,
                                String referenceType, UUID referenceId) {
        StockMovement movement = new StockMovement();
        movement.setStoreInventoryId(record.getId());
        movement.setQuantityDelta(quantityChange);
        movement.setBalanceAfter(record.getOnHand());
        movement.setType(type);
        movement.setReferenceType(referenceType);
        movement.setReason(reason);
        movement.setReferenceId(referenceId);
        movements.save(movement);
    }

    public static class ResourceNotFoundException extends RuntimeException {
        public ResourceNotFoundException(String resource, Object id) {
            super(resource + " not found: " + id);
        }
    }

    public static class InsufficientStockException extends RuntimeException {
        public InsufficientStockException(UUID productId, int available) {
            super("Insufficient stock for product " + productId + "; available=" + available);
        }
    }

    public static class ResourceConflictException extends RuntimeException {
        public ResourceConflictException(String message) {
            super(message);
        }
    }

    private String toSlug(String name) {
        return name == null ? "category" : name.trim().toLowerCase()
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-|-$", "");
    }
}
