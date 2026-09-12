package com.litha.api.model;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
public class HuntItem extends AuditedEntity {
    @Column(nullable = false) public String name;
    @Column(columnDefinition = "TEXT") public String description;
    public String referenceImageUrl;
    /** 1 = casual interest, 5 = must-have. Null means the legacy default (3). */
    public Integer priority = 3;
    public LocalDate foundAt;
    @Enumerated(EnumType.STRING) @Column(nullable = false) public HuntStatus status = HuntStatus.SEARCHING;
    @OneToOne public Stone stone;
}
