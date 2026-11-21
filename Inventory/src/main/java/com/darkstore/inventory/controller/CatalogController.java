package com.darkstore.inventory.controller;

import com.darkstore.inventory.domain.Category;
import com.darkstore.inventory.domain.Product;
import com.darkstore.inventory.dto.Dtos.CategoryRequest;
import com.darkstore.inventory.dto.Dtos.ProductRequest;
import com.darkstore.inventory.service.InventoryService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping
public class CatalogController {
    private final InventoryService inventory;

    public CatalogController(InventoryService inventory) {
        this.inventory = inventory;
    }

    @GetMapping("/categories")
    public List<Category> categories() {
        return inventory.listCategories();
    }

    @PostMapping("/categories")
    @ResponseStatus(HttpStatus.CREATED)
    public Category createCategory(@Valid @RequestBody CategoryRequest request) {
        return inventory.createCategory(request);
    }

    @GetMapping("/categories/{id}")
    public Category category(@PathVariable UUID id) {
        return inventory.getCategory(id);
    }

    @PutMapping("/categories/{id}")
    public Category updateCategory(@PathVariable UUID id, @Valid @RequestBody CategoryRequest request) {
        return inventory.updateCategory(id, request);
    }

    @DeleteMapping("/categories/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteCategory(@PathVariable UUID id) {
        inventory.deleteCategory(id);
    }

    @GetMapping("/products")
    public List<Product> products() {
        return inventory.listProducts();
    }

    @PostMapping("/products")
    @ResponseStatus(HttpStatus.CREATED)
    public Product createProduct(@Valid @RequestBody ProductRequest request) {
        return inventory.createProduct(request);
    }

    @GetMapping("/products/{id}")
    public Product product(@PathVariable UUID id) {
        return inventory.getProduct(id);
    }

    @PutMapping("/products/{id}")
    public Product updateProduct(@PathVariable UUID id, @Valid @RequestBody ProductRequest request) {
        return inventory.updateProduct(id, request);
    }

    @DeleteMapping("/products/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteProduct(@PathVariable UUID id) {
        inventory.deleteProduct(id);
    }
}
