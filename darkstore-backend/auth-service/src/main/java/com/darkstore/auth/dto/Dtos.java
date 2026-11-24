package com.darkstore.auth.dto;

import com.darkstore.auth.domain.Address;
import com.darkstore.auth.domain.Role;
import com.darkstore.auth.domain.Store;
import com.darkstore.auth.domain.User;
import com.darkstore.auth.domain.UserStatus;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public final class Dtos {

    private Dtos() {}

    // ---------- auth ----------

    public record RegisterRequest(
            @NotBlank @Size(max = 100) String fullName,
            @NotBlank @Email String email,
            @NotBlank @Size(min = 8, max = 72) String password,
            @Size(max = 20) String phone) {}

    public record LoginRequest(
            @NotBlank @Email String email,
            @NotBlank String password) {}

    public record RefreshRequest(@NotBlank String refreshToken) {}

    public record AuthResponse(String accessToken, String refreshToken, long expiresIn, UserResponse user) {}

    // ---------- users ----------

    public record UserResponse(UUID id, String email, String fullName, String phone,
                               Role role, UserStatus status, UUID storeId) {
        public static UserResponse from(User u) {
            return new UserResponse(u.getId(), u.getEmail(), u.getFullName(), u.getPhone(),
                    u.getRole(), u.getStatus(), u.getStoreId());
        }
    }

    public record UpdateProfileRequest(
            @NotBlank @Size(max = 100) String fullName,
            @Size(max = 20) String phone) {}

    // ---------- addresses ----------

    public record AddressRequest(
            @Size(max = 50) String label,
            @NotBlank @Size(max = 200) String line1,
            @Size(max = 200) String line2,
            @NotBlank @Size(max = 100) String city,
            @Size(max = 100) String state,
            @NotBlank @Size(max = 20) String postalCode,
            @Size(max = 100) String country,
            Boolean defaultAddress) {}

    public record AddressResponse(UUID id, String label, String line1, String line2, String city,
                                  String state, String postalCode, String country, Boolean defaultAddress) {
        public static AddressResponse from(Address a) {
            return new AddressResponse(a.getId(), a.getLabel(), a.getLine1(), a.getLine2(), a.getCity(),
                    a.getState(), a.getPostalCode(), a.getCountry(), a.isDefaultAddress());
        }
    }

    // ---------- stores ----------

    public record StoreRequest(
            @NotBlank @Size(max = 20) String code,
            @NotBlank @Size(max = 100) String name,
            @Size(max = 200) String line1,
            @Size(max = 100) String city,
            @Size(max = 100) String state,
            @Size(max = 20) String postalCode,
            @Size(max = 20) String phone,
            Boolean active) {}

    public record StoreResponse(UUID id, String code, String name, String line1, String city,
                                String state, String postalCode, String phone, boolean active) {
        public static StoreResponse from(Store s) {
            return new StoreResponse(s.getId(), s.getCode(), s.getName(), s.getLine1(), s.getCity(),
                    s.getState(), s.getPostalCode(), s.getPhone(), s.isActive());
        }
    }

    // ---------- admin ----------

    public record CreateStaffRequest(
            @NotBlank @Size(max = 100) String fullName,
            @NotBlank @Email String email,
            @NotBlank @Size(min = 8, max = 72) String password,
            @Size(max = 20) String phone,
            @NotNull Role role,
            UUID storeId) {}

    public record StatusRequest(@NotNull UserStatus status) {}
}
