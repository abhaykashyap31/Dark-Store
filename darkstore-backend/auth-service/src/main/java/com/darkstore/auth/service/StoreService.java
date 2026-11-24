package com.darkstore.auth.service;

import com.darkstore.auth.domain.Store;
import com.darkstore.auth.dto.Dtos.StoreRequest;
import com.darkstore.auth.dto.Dtos.StoreResponse;
import com.darkstore.auth.repo.StoreRepository;
import com.darkstore.auth.exception.ApiException;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class StoreService {

    private final StoreRepository stores;

    public StoreService(StoreRepository stores) {
        this.stores = stores;
    }

    @Transactional(readOnly = true)
    public List<StoreResponse> list() {
        return stores.findAll(Sort.by("id")).stream().map(StoreResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public StoreResponse get(UUID id) {
        return StoreResponse.from(find(id));
    }

    public StoreResponse create(StoreRequest r) {
        String code = r.code().trim().toUpperCase();
        if (stores.existsByCodeIgnoreCase(code)) {
            throw codeExists();
        }
        Store s = new Store();
        s.setCode(code);
        apply(s, r);
        return StoreResponse.from(stores.save(s));
    }

    public StoreResponse update(UUID id, StoreRequest r) {
        Store s = find(id);
        String code = r.code().trim().toUpperCase();
        if (stores.existsByCodeIgnoreCaseAndIdNot(code, id)) {
            throw codeExists();
        }
        s.setCode(code);
        apply(s, r);
        return StoreResponse.from(stores.save(s));
    }

    private static void apply(Store s, StoreRequest r) {
        s.setName(r.name().trim());
        s.setLine1(r.line1());
        s.setCity(r.city());
        s.setState(r.state());
        s.setPostalCode(r.postalCode());
        s.setPhone(r.phone());
        if (r.active() != null) {
            s.setActive(r.active());
        }
    }

    private Store find(UUID id) {
        return stores.findById(id).orElseThrow(() -> ApiException.notFound("Store"));
    }

    private static ApiException codeExists() {
        return new ApiException(HttpStatus.CONFLICT, "STORE_CODE_EXISTS", "A store with this code already exists");
    }
}
