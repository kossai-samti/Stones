package com.litha.api.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
public class MemoryPhoto extends AuditedEntity {
    @ManyToOne(optional = false) @JsonIgnore public Memory memory;
    @Column(nullable = false) public String imageUrl;
    @Column(nullable = false) public int displayOrder;
}
