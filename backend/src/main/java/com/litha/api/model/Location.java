package com.litha.api.model;

import jakarta.persistence.Entity;

@Entity
public class Location extends AuditedEntity {
    public String name;
    public Double latitude;
    public Double longitude;
    public String country;
}
