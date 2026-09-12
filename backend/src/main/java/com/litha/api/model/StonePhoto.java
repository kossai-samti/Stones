package com.litha.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;

@Entity
public class StonePhoto extends AuditedEntity {
    @ManyToOne(optional = false)
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    public Stone stone;
    @Column(nullable = false) public String imageUrl;
    public String caption;
    @Column(nullable = false) public boolean primaryPhoto;
    @Column(nullable = false) public int displayOrder;

    @JsonProperty("stoneId")
    @Transient
    public Long getStoneId() { return stone == null ? null : stone.id; }
}
