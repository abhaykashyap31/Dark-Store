package com.darkstore.auth.service;

import com.darkstore.auth.domain.Address;
import com.darkstore.auth.domain.User;
import com.darkstore.auth.dto.Dtos.AddressRequest;
import com.darkstore.auth.dto.Dtos.AddressResponse;
import com.darkstore.auth.dto.Dtos.UpdateProfileRequest;
import com.darkstore.auth.dto.Dtos.UserResponse;
import com.darkstore.auth.repo.AddressRepository;
import com.darkstore.auth.repo.UserRepository;
import com.darkstore.auth.exception.ApiException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class UserService {

    private final UserRepository users;
    private final AddressRepository addresses;

    public UserService(UserRepository users, AddressRepository addresses) {
        this.users = users;
        this.addresses = addresses;
    }

    @Transactional(readOnly = true)
    public UserResponse me(UUID userId) {
        return UserResponse.from(find(userId));
    }

    public UserResponse updateMe(UUID userId, UpdateProfileRequest r) {
        User u = find(userId);
        u.setFullName(r.fullName().trim());
        u.setPhone(r.phone());
        return UserResponse.from(users.save(u));
    }


    @Transactional(readOnly = true)
    public List<AddressResponse> listAddresses(UUID userId) {
        return addresses.findByUser_IdOrderByIdAsc(userId).stream().map(AddressResponse::from).toList();
    }

    public AddressResponse addAddress(UUID userId, AddressRequest r) {
        Address a = new Address();
        a.setUser(find(userId));
        copy(a, r);
        boolean first = addresses.findByUser_IdOrderByIdAsc(userId).isEmpty();
        boolean makeDefault = first || Boolean.TRUE.equals(r.defaultAddress());
        if (makeDefault) {
            clearDefault(userId);
        }
        a.setDefaultAddress(makeDefault);
        return AddressResponse.from(addresses.save(a));
    }

    public AddressResponse updateAddress(UUID userId, UUID id, AddressRequest r) {
        Address a = addresses.findByIdAndUser_Id(id, userId).orElseThrow(() -> ApiException.notFound("Address"));
        copy(a, r);
        if (Boolean.TRUE.equals(r.defaultAddress())) {
            clearDefault(userId);
            a.setDefaultAddress(true);
        }
        return AddressResponse.from(addresses.save(a));
    }

    public void deleteAddress(UUID userId, UUID id) {
        Address a = addresses.findByIdAndUser_Id(id, userId).orElseThrow(() -> ApiException.notFound("Address"));
        addresses.delete(a);
    }


    private User find(UUID id) {
        return users.findById(id).orElseThrow(() -> ApiException.notFound("User"));
    }

    private static void copy(Address a, AddressRequest r) {
        a.setLabel(r.label());
        a.setLine1(r.line1());
        a.setLine2(r.line2());
        a.setCity(r.city());
        a.setState(r.state());
        a.setPostalCode(r.postalCode());
        a.setCountry(r.country());
    }

    private void clearDefault(UUID userId) {
        for (Address other : addresses.findByUser_IdOrderByIdAsc(userId)) {
            if (other.isDefaultAddress()) {
                other.setDefaultAddress(false);
                addresses.save(other);
            }
        }
    }
}
